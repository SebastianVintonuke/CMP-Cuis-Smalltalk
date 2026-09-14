# Findings

Problems met during the experiment, with the evidence that exposed them, their cause, and what was done about them. Measurements were taken informally on one machine with Cuis 7.8. Decisions (D1 to D11) are in [decisions.md](decisions.md).

Status values: **Resolved**, **Mitigated**, **Open**, and **Suspected** for issues identified by reading the code but not reproduced.

## Resolved or mitigated

### F1. Compute-bound calls blocked the UI and other requests

**Evidence.** With the server running inside the image, before any change to process priorities:

| Case | Result |
| --- | --- |
| A call that waits (a 5-second `Delay`), with a second request sent in parallel | The second request answered in 19 ms |
| A call that computes (a 6-second loop), with a second request sent in parallel | The second request took 5.01 s: it waited for the first call to finish |
| A busy loop running for 6 seconds | 387,532,240 iterations, about 64 million per second |

Request handlers and the `WebServer` listener ran at priority 60, above the UI at 50 (full table in [execution and concurrency](architecture.md#execution-and-concurrency)).

**Cause.** Cuis runs every Smalltalk process on one VM and one OS thread. A process that computes does not yield, and only a process of higher priority can preempt it. Request handlers run above the UI, so a compute-bound call took the CPU from every other request and from the human's interface. The server is not at fault as such: the VM offers no parallelism to use.

**Resolution.** Mitigated by running tool calls in a worker process below the UI priority (D6) and by cancellation from the client (D7).

**Remaining limits.**

- A call that blocks the whole VM inside a primitive, such as a blocking read from standard input (observed), cannot be cancelled. The only way out is to kill the VM from outside, which loses unsaved state; code that was evaluated remains in the `.changes` file.
- Evaluated code can raise its own priority. Above the request handlers (60), a call can only be cancelled while it waits. `demo/cancel-demo.st` shows this on purpose.

### F2. Request and response bodies were not UTF-8

**Evidence.** A request containing `café` (bytes `63 61 66 c3 a9`) reached the tool as five characters instead of four. Responses looked correct by accident: the two wrong characters read on input were written back as the same two bytes. MCP requires JSON-RPC messages to be UTF-8, so this was a protocol violation.

**Cause.** The Cuis HTTP layer works in bytes in both directions. Request content arrives as a string with one character per byte, and `sendResponse:content:` uses the string size as the byte length.

**Resolution.** Resolved in the adapter, not in the protocol. `MCPServer>>textFromWire:` decodes the body with `String fromUtf8Bytes:`, and `wireStringFor:` encodes the response with `asUtf8Bytes`, the same pieces `WebClient` uses. Inside the server everything is text. After the change, the same request answered four characters, and the accented character went out as the bytes `c3 a9`. Covered by `MCPServerTest>>test09DecodesTheBodyAsUtf8` and `test10EncodesTheResponseAsUtf8`.

**Related facts.**

- `String>>asUtf8BytesOrByteString` fails in this image (`SmallInteger>>isSeparator`), so the response is built byte by byte.
- File-outs were already UTF-8, because the VM is launched with `-encoding UTF-8`. Nothing changed there; `MCPServerBrowserToolsTest>>test21WritesTheFileOutAsUtf8` guards the behavior in case the VM is launched differently.

### F3. Defects that only end-to-end runs exposed

Unit tests call the facades and `MCPServer>>handleRequestBody:` directly. Using the running server over HTTP exposed three defects that they did not:

- **HTTP 500 on every request.** `MCPServer>>handleRequest:` used `body ifNil: [...] ifFalse: [...]`. In Cuis `ifNil:ifFalse:` is understood by `nil` but not by other objects, and no unit test went through `handleRequest:`. Fixed with `isNil ifTrue:ifFalse:`.
- **State shared between servers.** A long-running demo server answered `tools/list` with the catalogue of the last server the tests had created. `MCPServer` had been defined with no instance variables, so the compiler bound `port`, `catalogue` and `webServer` in its methods to `Undeclared`, making them globals shared by every instance. The symptom suggested a `WebServer` problem; the cause was an empty `instanceVariableNames:`. Fixed by declaring the variables, recompiling the methods and removing the stale bindings from `Undeclared`. Covered by `MCPServerTest>>test05TwoServersDoNotShareTheirState`.
- **A misleading empty category.** For a class side without methods, `selectors_of_class` listed the empty `as yet unclassified` category that the image keeps. It now answers `no methods` (`MCPServerBrowserToolsTest>>test12DoesNotSayAsYetUnclassified`).

**Resolution.** Resolved. Tests that go through real HTTP requests were added later for the transport behavior (`MCPServerTest>>test11` and `test12`).

### F4. A new image blocks on a modal author prompt

**Evidence.** In a fresh image, a startup script that compiled code never finished. This happened twice before the cause was addressed.

**Cause.** The first time code is changed in an image without an author, Cuis asks for one with a dialog (`Utilities>>setAuthor`) that waits for an answer. Reading the author with `Utilities authorInitials` opens the same dialog; `Utilities authorInitialsPerSe` reads it without asking.

**Resolution.** Resolved. `MCPServer>>start` checks `authorInitialsPerSe` and fails with an explicit message when there is no author. The policy behind the check is D9.

### F5. A test that ran its own category froze the image

**Evidence.** The first Test Runner test ran the whole `MCPServerTest` category, which contains that test, so the suite called itself recursively. The image went to 100% CPU and stopped answering on every port, and the VM exited when it was interrupted from outside. No code was lost: the package had been filed out to `src/`, and every change was in the `.changes` file.

**Resolution.** Resolved. `MCPServerTestingToolsTest>>test02TakesEveryTestClassOfTheCategory` checks which test classes a category run would include, without running them. Running a category is exercised from outside, through the `run_tests_in_category` tool, which is how it is meant to be used.

### F6. Process and semaphore semantics

Facts about Cuis 7.8 established while building the worker process and cancellation, several of them after a wrong assumption:

- **`[ ... ] ensure: [ ... ]` does not build a process body.** It evaluates the block immediately and answers its value. To protect the body of a process, the `ensure:` goes inside the block that becomes the process: `[ [ ... ] ensure: [ ... ] ] newProcess`.
- **`Semaphore new critical: [ ... ]` never enters.** A new semaphore has no signals, so the block waits forever. A mutex is `Semaphore forMutualExclusion`. While this was being diagnosed, `Transcript` was briefly suspected; `Transcript show:` from a worker returns without blocking.
- **`Semaphore>>waitTimeoutMSecs:` answers `true` when the timeout expired and `false` when a signal arrived.** The first experiment assumed the opposite and concluded that `ensure:` did not wake the waiting process. Testing the instrument on its own showed the experiment was wrong. When a measurement contradicts the source code, check the measurement first.
- **`Process>>terminate` runs pending `ensure:` blocks before it returns.** The cancellation design relies on this, and it was measured: a file written by the `ensure:` block was already on disk when `terminate` returned.
- **A process terminated before it ever runs does not run its `ensure:` blocks.** Unwinding starts from the stack the process has, and the `ensure:` has not been sent yet. For this reason `MCPServerInFlightRequests>>cancel:` removes the registry entry itself instead of relying on the worker (`MCPServerInFlightRequestsTest>>test07CancellingACallThatHasNotStartedYet`). The same fact leads to [O8](#o8-cancellation-before-the-worker-runs).
- **`suspendedContext isNil` does not mean that a process has terminated.** A running process can also have it `nil`. Assuming otherwise terminated the worker of the request in progress. `isSuspended` answers `true` for a process that has been created and not yet resumed, and `false` after `resume`.
- **A bare identifier is always a variable.** Inside `MCPServer>>protocol`, `inFlight` is the instance variable, not a send of the lazily initializing accessor with the same name. The accessor never ran and the protocol received `nil`. The resolution was to have the protocol ignore a cancellation when there is no registry, which the specification allows (`MCPServerTest>>test13AServerBornBeforeTheRegistryIgnoresACancellation`).

**Status.** Resolved; each fact is reflected in the code and tests cited.

### F7. Pitfalls of image-based development over HTTP

- **Renaming a test does not remove the old one.** In an image a method is identified by its selector: compiling a test under a new name adds a method and leaves the old one in place. It happened three times. Three versions of `test06` coexisted and the oldest called deleted code, so the suite did not run; later an old copy of `test13` kept failing on an expectation that no longer held. Two more leftovers, `test09DecodesTheBodyAsUtf8` and `test10EncodesTheResponseAsUtf8` compiled into the production class `MCPServer`, were found and removed from the file-out while this documentation was prepared. When an expectation changes, the test keeps its selector and changes its body.
- **Numbers in assertions go stale.** A Test Runner test expected "2 tests" for `MCPServerToolTest` and broke when a third test was added. The expected count now comes from the class.
- **Source nested in requests breaks on quotes.** A quote inside a Smalltalk string that is itself source code must be doubled. Twice a test compiled only partially and the request answered `nil` with no error. Test sources were then written to files and compiled from there, which removed the problem and left the tests in reviewable files.
- **A script is compiled as a whole before it runs.** A syntax error anywhere, including temporaries declared in the middle of a script, means that nothing runs ([O7](#o7-errors-that-do-not-surface)).
- **Keyword messages extend to the end of the expression.** `self isQuote: ch or: [...]` parses as one message, `isQuote:or:`, and `self isQuote: ch ifTrue: [...]` as `isQuote:ifTrue:`. Both failed with `MessageNotUnderstood` naming the combined selector.
- **Selectors from other dialects.** `removeSelector:ifAbsent:` does not exist in Cuis.
- **File-out details.** `FileEntry>>writeStreamDo:` does not replace an existing file, so `file_out_package_to` deletes the target first. A class is filed out with the package of its system category, so `MCPServerTest` had to move to the `MCPServerTest` category to leave the production package.

**Status.** Resolved as working practices.

## Open issues

### O1. Concurrent edits by the human and the agent

**Evidence.** Cuis does not protect against this. `CodeProvider>>okayToAccept`, the last check before a Browser accepts a method, only verifies that the pane is not showing bytecodes or a diff. It does not check whether the method changed since it was displayed. If the agent compiles `Foo>>bar` while the human has it open, and the human accepts later, the human's version replaces the agent's without notice. In the other direction, the human's pane keeps showing outdated source.

**Analysis.** There are three kinds of conflict, with different remedies:

| Conflict | Example | Candidate remedy |
| --- | --- | --- |
| Same method | The human has the source open while the agent compiles it | Optimistic concurrency: reads answer a version token, and writes require it and fail with the current source when it changed |
| Structure | Removing or renaming a class the human has open; recompiling a class while a stack frame refers to it | Rules similar to those the Process Browser applies to processes (D11) |
| Shared system resources | The compiler, `SystemOrganizer`, `ChangeSet`, `Preferences` | A policy on which targets the agent may modify, since no merge is possible |

**Status.** Open, accepted as a known limitation. Optimistic concurrency, serialized writes, an agent change set and checkpoints were left out deliberately ([deferred](decisions.md#deferred-and-out-of-scope)). Locking the human out, or patching the Browser's accept path, was rejected: it would impose on the human a rule the agent does not have.

### O2. Stale server handles and silent listeners

**Evidence.**

- A server does not survive saving and reopening the image. The image keeps the object (for example in a global such as `MCPDemo`) but not its socket or its listener. After reopening, the global refers to a server that still answers its `port`, its `catalogue` and its tool list, because those are data of the object, while nothing is listening. During the experiment this combined with the shared-state defect of [F3](#f3-defects-that-only-end-to-end-runs-exposed) and took time to understand.
- A worse state is a socket in `LISTEN` with no process accepting connections. Clients do not get `connection refused`; they wait. It was reproduced in two ways:
  1. stopping the listener while leaving the socket open (`WebServer>>stopListener`);
  2. destroying the server from a request that the same server is serving. `destroy` terminates the connections in progress, including the one running the request, and the socket is left listening with nothing accepting.
- The state is **not** produced by the VM dying (the operating system closes its sockets and frees the port), nor by destroying and recreating a server from a request served by a different server.

**Mitigations in place.** `isListening` reports whether a server has a listener process; its answer for a server restored from a saved image was not verified. `start` fails explicitly when the port is taken, and the README shows how to release a port from the image (D8). Guidance: do not destroy a server from a request it is serving.

**Options, not decided.**

- Clear server globals when the image starts: cheap and avoids the confusion, but it needs a hook into Cuis startup.
- Avoid globals: keep the server in a Workspace variable or in an object that is recreated at startup.
- Make a restored server recognize that it is no longer listening, so that `start` works on it again.

**Status.** Open.

### O3. Multi-step operations need review state and transactions

**Evidence.** Some window operations are not a single step: they propose a change, show it, wait for the human's approval and then apply it. Renaming a selector is the first such case, and the only operation in scope that could not be turned into a tool. Renaming a class works without a UI (`Smalltalk renameClassNamed:as:` updates references to the global). Renaming a selector does not: the implementation lives in `Browser>>renameSelector` and in the editor, and goes through `RefactoringApplier` with the editor's text. `RenameSelector` on its own is only a helper. Doing it by hand means rewriting the source of every sender, which breaks silently with multi-keyword selectors, nested sends and string literals that contain the selector.

**Analysis.** There are two separate problems:

1. **Review needs state.** "Waiting for approval" lives in the window. The server keeps no state between requests, deliberately, since that lets the catalogue be shared without locks. The Debugger needs the same thing: a session that survives between calls.
2. **There are no transactions.** The image has no all-or-nothing update. If one sender fails to compile halfway through, the rename is left partial, with some senders updated and the old selector already removed. The change set records everything, so it can be reverted by hand, but the server cannot promise atomicity. The proposed mitigation is to validate before changing anything: compute each sender's new source and compile it without installing it, using the Cuis compiler; if any fails, abort with nothing changed. Applying then only installs sources already known to compile.

**Status.** Open, deferred. Renaming a selector with senders stays in the Browser, where the human sees the diff. Without senders, the existing tools are enough: compile the method under the new selector and remove the old one, after checking with `all_calls_on` that there are no senders. Stateful sessions would address this and the Debugger together.

### O4. UI actions from non-UI processes

Evaluated code can open windows. During the experiment this worked from a request handler, although the handler is not the UI process, and tool calls now run in a worker process, which is not the UI process either. The Cuis convention is to defer such actions to the UI process with `UISupervisor whenUIinSafeState:`. The current behavior works, but it is the kind of shortcut that fails in subtle ways.

**Status.** Open, not addressed.

### O5. Unexplained scheduling anomaly

In an early experiment, a forked process running a `whileTrue` loop with a `Delay` inside stopped the main process from ever running again, although both had the same priority (40). This was not explained. The server relies on the same scheduling mechanism, so it should be understood before building further on it.

**Status.** Open.

### O6. Growth of processes and change sets

Each request creates a handler process and each tool call a worker process, and every change the agent makes adds to the image's change sets. There is no way to discard the agent's changes as a unit, and no decision on what should happen to them when the image is saved.

**Status.** Open, not decided.

### O7. Errors that do not surface

**Evidence.**

- **Syntax errors in evaluated code.** During development, code with a syntax error sent for evaluation answered `nil` with no error: `Compiler evaluate:` did not report the error, and since a script is compiled as a whole, nothing in it ran. `print_it` evaluates with `Compiler evaluate:`, so an agent can receive `nil` for code that did not compile. By contrast, `compile_method_in_class_classified` reports syntax errors (`MCPServerBrowserToolsTest>>test09SignalsASyntaxError`).
- **Errors inside tests.** In Cuis, `TestResult>>runCase:` counts test errors by handling `UnhandledError`. When a suite runs inside an outer `on: Error do:`, an unexpected error in a test does not match SUnit's handler and is taken by the outer one: the whole run is aborted instead of the error being counted, while assertion failures are still counted. This was observed when running tests through a development endpoint that handled `Error`.

**Suspected consequence, not verified.** `MCPServerTool` runs every tool inside `on: Error do:`. `run_tests_in_class` and `run_tests_in_category` may therefore answer an error result for a suite that contains a test raising an error, instead of a summary that counts it. `MCPServerTestingToolsTest>>test01RunsTheTestsOfATestClass` runs only passing tests, and calls the facade directly rather than through `MCPServerTool`.

**Status.** Open. The syntax-error behavior was observed; the Test Runner consequence is suspected.

### O8. Cancellation before the worker runs

**Status.** Suspected. Identified by reading the code while this documentation was prepared; not reproduced.

**Analysis.** `MCPServerTool>>executeWith:under:in:` registers the worker, resumes it, and waits on a semaphore that only the worker's `ensure:` block signals. A worker terminated before it first runs never executes that block ([F6](#f6-process-and-semaphore-semantics)). `MCPServerInFlightRequests>>cancel:` already removes the registry entry in that case, but nothing signals the semaphore.

The window exists because the worker runs at priority 40. After `resume`, the worker starts only when no process of higher priority is ready; for example, not while the UI process is busy with an evaluation the human started. If a cancellation for that request arrives in that interval, the handler of the cancelled request would wait indefinitely, keeping its process and its HTTP connection open. The existing test for this path (`MCPServerInFlightRequestsTest>>test07CancellingACallThatHasNotStartedYet`) exercises the registry with a bare process, not through `MCPServerTool`.

**Possible fix and test.** Register, together with the worker, an action that signals the waiting semaphore, and have `cancel:` run it after terminating the process. A test would keep the CPU busy with a process of higher priority, start a call through `MCPServerTool`, cancel it before the worker runs, and check that the call returns.
