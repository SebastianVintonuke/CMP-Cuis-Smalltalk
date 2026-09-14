# Development log

How the package was developed, and the order in which tests drove the implementation. The problems met along the way are described once, in [findings.md](findings.md), and linked from here.

## Development process

The package was developed test-first with an AI coding agent that operated a live Cuis 7.8 image, under the author's direction. The author set the direction and made the design and scope decisions, including:

- attributing the agent's changes to the image owner instead of giving the agent its own author stamp ([D9](decisions.md#d9-attribute-changes-to-the-image-owner));
- removing a `restart` that took over ports held by other listeners ([D8](decisions.md#d8-do-not-take-host-resources));
- the text of the handshake `instructions`, and the absence of warnings in the tool surface ([D10](decisions.md#d10-the-handshake-describes-the-environment-not-rules));
- leaving optimistic concurrency control out of scope ([deferred scope](decisions.md#deferred-and-out-of-scope)).

The agent reached the image over HTTP. The first cycles used a separate development endpoint that evaluated code in the image. Once the server had its Browser and Test Runner tools, the rest of the work (reading code, compiling methods, running the tests and filing out the package) went through the MCP server being built, and the separate endpoint was no longer needed.

Several findings come from mistakes made in this process, such as misreading a semaphore's return value, terminating the wrong process or leaving renamed tests behind ([F6](findings.md#f6-process-and-semaphore-semantics), [F7](findings.md#f7-pitfalls-of-image-based-development-over-http)). They are recorded because they show how the environment behaves and where agent-driven work in a live image goes wrong.

## Method

Each cycle added one test for behavior that did not exist yet, ran it to see it fail, recorded the failure, implemented the minimum to make it pass, and ran the tests again. Test sources were written to files and compiled in the image from there, which avoided quoting errors when source code was nested inside requests ([F7](findings.md#f7-pitfalls-of-image-based-development-over-http)).

Some tests were written after the behavior they cover, as regression guards rather than red-green cycles. They are marked as guards below.

## Milestones

| # | Milestone | Red evidence | Implemented | Tests after |
| --- | --- | --- | --- | --- |
| 1 | `print_it` and the declaration pipeline | Classes that did not exist yet (`UndefinedObject>>new`, `>>forMethod:`, `>>fromSource:`, `>>on:`, `>>buildFrom:`); a failing expression raised instead of answering a result | The Workspace facade and `printIt:` with its pragma; the descriptor, method-comment reader, tool, result, catalogue and builder; errors as `isError` results | 7 |
| 2 | MCP flow | `MCPServerProtocol` and `MCPServer class>>on:tools:` did not exist | `initialize`, `tools/list`, `tools/call`, unknown tools, tool errors and notifications; the `/mcp` endpoint on loopback. Checked end to end over HTTP, which exposed a defect the unit tests missed ([F3](findings.md#f3-defects-that-only-end-to-end-runs-exposed)) | Not recorded |
| 3 | Browser: reading and writing methods | The facade, then each selector, did not exist | `selectors_of_class`, `source_of_method_in_class`, `comment_of_class`, `all_calls_on`, `compile_method_in_class_classified`, `remove_method_in_class`. End-to-end use exposed two more defects, each fixed with a test ([F3](findings.md#f3-defects-that-only-end-to-end-runs-exposed)) | 31 |
| 4 | Window provenance | `key: '_meta' not found` | `_meta.system` in `tools/list` | 32 |
| 5 | Browser: implementors, hierarchy, method categories; shared class lookup | Not recorded; the refactoring had no red step, since existing tests covered it | `all_implementors_of`, `hierarchy_of_class`, `classify_method_in_class_under`; `MCPServerEnvironment` extracted from the Browser facade | 35 |
| 6 | Test Runner and file out | The facade and `fileOutPackage:to:` did not exist | `run_tests_in_class`, `run_tests_in_category`, `file_out_package_to`; the dependencies on `WebClient` and `JSON` declared in the package ([F5](findings.md#f5-a-test-that-ran-its-own-category-froze-the-image)) | 39 |
| 7 | Attribution of changes | Not recorded | A distinct agent stamp, implemented and then reverted; `start` requires an author ([D9](decisions.md#d9-attribute-changes-to-the-image-owner), [F4](findings.md#f4-a-new-image-blocks-on-a-modal-author-prompt)) | Not recorded |
| 8 | Start and stop | A second `start` failed with a low-level `Failed to listen` error | `isListening`; explicit errors for "already listening" and "port taken"; the forced `restart` removed ([D8](decisions.md#d8-do-not-take-host-resources)) | 41 |
| 9 | Class listing and search | `classesInCategory:` did not exist | `classes_in_category`, `classes_matching`, `methods_containing`; the bounded listing extracted into one method | 44 |
| 10 | Class definition, removal and renaming | `defineClass:subclassOf:variables:category:` did not exist | `define_class_subclass_of_variables_category`, `remove_class`, `rename_class_to`. Renaming a selector was analyzed and deliberately left out ([O3](findings.md#o3-multi-step-operations-need-review-state-and-transactions)) | 48 |
| 11 | UTF-8 at the HTTP boundary | A body containing `café` reached the tool as five characters | `textFromWire:` and `wireStringFor:`; a file-out encoding test, as a guard, since it passed on its first run ([F2](findings.md#f2-request-and-response-bodies-were-not-utf-8)) | 50 |
| 12 | Handshake instructions | The `instructions` field did not exist | `MCPServerProtocol>>instructions` ([D10](decisions.md#d10-the-handshake-describes-the-environment-not-rules)) | 52 |
| 13 | Worker process below the UI | The tool reported priority 60, the handler's | The worker process and semaphore in `MCPServerTool` ([D6](decisions.md#d6-run-agent-work-below-the-ui-priority)) | 53 |
| 14 | Cancellation | The registry, the registration in the tool and the notification handling did not exist | The in-flight registry with handles; registration before `resume`; `notifications/cancelled`. Guards: `202` for messages with no response, and cancellation over HTTP with two clients. A server created before the registry existed ignores cancellations, found against the running server ([D7](decisions.md#d7-cancellation-belongs-to-the-client), [F6](findings.md#f6-process-and-semaphore-semantics)) | 70 |

## Notes on the record

- The original log numbered individual cycles, with gaps; the numbering is not kept here, and each milestone groups consecutive cycles.
- Test counts are those recorded when a milestone closed. Where none was recorded, the table says so.
- Early in the work, the tests were split from a single class into one test class per class under test, all in the `MCPServerTest` category.
