'Description Tests for the MCPServer package.'!
!provides: 'MCPServerTest' 1 1!
SystemOrganization addCategory: #MCPServerTest!


!classDefinition: #MCPServerMethodCommentTest category: #MCPServerTest!
TestCase subclass: #MCPServerMethodCommentTest
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'MCPServerTest'!
!classDefinition: 'MCPServerMethodCommentTest class' category: #MCPServerTest!
MCPServerMethodCommentTest class
	instanceVariableNames: ''!

!classDefinition: #MCPServerProtocolTest category: #MCPServerTest!
TestCase subclass: #MCPServerProtocolTest
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'MCPServerTest'!
!classDefinition: 'MCPServerProtocolTest class' category: #MCPServerTest!
MCPServerProtocolTest class
	instanceVariableNames: ''!

!classDefinition: #MCPServerTest category: #MCPServerTest!
TestCase subclass: #MCPServerTest
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'MCPServerTest'!
!classDefinition: 'MCPServerTest class' category: #MCPServerTest!
MCPServerTest class
	instanceVariableNames: ''!

!classDefinition: #MCPServerToolCatalogueTest category: #MCPServerTest!
TestCase subclass: #MCPServerToolCatalogueTest
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'MCPServerTest'!
!classDefinition: 'MCPServerToolCatalogueTest class' category: #MCPServerTest!
MCPServerToolCatalogueTest class
	instanceVariableNames: ''!

!classDefinition: #MCPServerToolDescriptorTest category: #MCPServerTest!
TestCase subclass: #MCPServerToolDescriptorTest
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'MCPServerTest'!
!classDefinition: 'MCPServerToolDescriptorTest class' category: #MCPServerTest!
MCPServerToolDescriptorTest class
	instanceVariableNames: ''!

!classDefinition: #MCPServerToolTest category: #MCPServerTest!
TestCase subclass: #MCPServerToolTest
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'MCPServerTest'!
!classDefinition: 'MCPServerToolTest class' category: #MCPServerTest!
MCPServerToolTest class
	instanceVariableNames: ''!

!classDefinition: #MCPServerWorkspaceToolsTest category: #MCPServerTest!
TestCase subclass: #MCPServerWorkspaceToolsTest
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'MCPServerTest'!
!classDefinition: 'MCPServerWorkspaceToolsTest class' category: #MCPServerTest!
MCPServerWorkspaceToolsTest class
	instanceVariableNames: ''!


!MCPServerMethodCommentTest commentStamp: '<historical>' prior: 0!
I test the reader of a method comment, which is where the tool description comes from.!

!MCPServerProtocolTest commentStamp: '<historical>' prior: 0!
I test the MCP protocol: the message in, the response out.!

!MCPServerToolCatalogueTest commentStamp: '<historical>' prior: 0!
I test the catalogue: the set of tools exposed, built from the declarations.!

!MCPServerToolDescriptorTest commentStamp: '<historical>' prior: 0!
I test the descriptor: what a tool declaration says, as data.!

!MCPServerToolTest commentStamp: '<historical>' prior: 0!
I test the tool as a command: running it and answering a result.!

!MCPServerWorkspaceToolsTest commentStamp: '<historical>' prior: 0!
I test the Workspace facade: the operations it exposes as tools.!

!MCPServerMethodCommentTest methodsFor: 'as yet unclassified' stamp: 'S.V. 13/Sep/2026 12:31:29'!
test01AnswersTheCommentOfAMethodSource
	"The comment is the first quoted text after the message pattern; without it, nil."
	self assert: (MCPServerMethodComment fromSource: 'foo: aName
	"Does something with aName."
	^ aName') equals: 'Does something with aName.'.
	self assert: (MCPServerMethodComment fromSource: 'foo: aName
	^ aName') isNil! !

!MCPServerProtocolTest methodsFor: 'as yet unclassified' stamp: 'S.V. 13/Sep/2026 12:32:11'!
callRequestFor: aToolName arguments: aDictionary
	| request params |
	request := self requestMethod: 'tools/call' id: 3.
	params := Dictionary new.
	params at: 'name' put: aToolName.
	params at: 'arguments' put: aDictionary.
	request at: 'params' put: params.
	^ request! !

!MCPServerProtocolTest methodsFor: 'as yet unclassified' stamp: 'S.V. 13/Sep/2026 12:32:11'!
newProtocol
	^ MCPServerProtocol
		on: (MCPServerCatalogueBuilder buildFrom: { MCPServerWorkspaceTools })! !

!MCPServerProtocolTest methodsFor: 'as yet unclassified' stamp: 'S.V. 13/Sep/2026 12:32:11'!
requestMethod: aString id: anId
	| request |
	request := Dictionary new.
	request at: 'jsonrpc' put: '2.0'.
	request at: 'id' put: anId.
	request at: 'method' put: aString.
	^ request! !

!MCPServerProtocolTest methodsFor: 'as yet unclassified' stamp: 'S.V. 13/Sep/2026 12:32:11'!
test01InitializeAnswersTheProtocolVersionAndTheToolsCapability
	| response result |
	response := self newProtocol handleMessage: (self requestMethod: 'initialize' id: 1).
	result := response at: 'result'.
	self assert: (response at: 'id') equals: 1.
	self assert: (result at: 'protocolVersion') equals: '2025-06-18'.
	self assert: ((result at: 'capabilities') includesKey: 'tools').
	self assert: ((result at: 'serverInfo') at: 'name') equals: 'MCPServer'! !

!MCPServerProtocolTest methodsFor: 'as yet unclassified' stamp: 'S.V. 13/Sep/2026 12:32:11'!
test02ToolsListDescribesTheDeclaredTools
	| response tools tool schema |
	response := self newProtocol handleMessage: (self requestMethod: 'tools/list' id: 2).
	tools := (response at: 'result') at: 'tools'.
	self assert: tools size equals: 1.
	tool := tools first.
	self assert: (tool at: 'name') equals: 'print_it'.
	self assert: ((tool at: 'description') beginsWith: 'Evaluate aCodeString').
	schema := tool at: 'inputSchema'.
	self assert: (schema at: 'type') equals: 'object'.
	self assert: ((schema at: 'properties') includesKey: 'code').
	self assert: (schema at: 'required') equals: #('code')! !

!MCPServerProtocolTest methodsFor: 'as yet unclassified' stamp: 'S.V. 13/Sep/2026 12:32:11'!
test03ToolsCallRunsTheToolAndAnswersItsText
	| response result content |
	response := self newProtocol handleMessage:
		(self callRequestFor: 'print_it'
			arguments: (Dictionary new at: 'code' put: '2 * 3'; yourself)).
	result := response at: 'result'.
	self assert: (result at: 'isError') equals: false.
	content := result at: 'content'.
	self assert: content size equals: 1.
	self assert: ((content first) at: 'type') equals: 'text'.
	self assert: ((content first) at: 'text') equals: '6'! !

!MCPServerProtocolTest methodsFor: 'as yet unclassified' stamp: 'S.V. 13/Sep/2026 12:32:11'!
test04AnUnknownToolAnswersAProtocolError
	| response |
	response := self newProtocol handleMessage:
		(self callRequestFor: 'nope' arguments: Dictionary new).
	self assert: (response includesKey: 'error').
	self assert: ((response at: 'error') at: 'code') equals: -32602! !

!MCPServerProtocolTest methodsFor: 'as yet unclassified' stamp: 'S.V. 13/Sep/2026 12:32:43'!
test05AFailingToolAnswersAnErrorResult
	| response result text |
	response := self newProtocol handleMessage:
		(self callRequestFor: 'print_it'
			arguments: (Dictionary new at: 'code' put: '1 zork'; yourself)).
	result := response at: 'result'.
	self assert: (result at: 'isError') equals: true.
	text := ((result at: 'content') first) at: 'text'.
	self assert: (text beginsWith: 'MessageNotUnderstood')! !

!MCPServerProtocolTest methodsFor: 'as yet unclassified' stamp: 'S.V. 13/Sep/2026 12:32:11'!
test06ANotificationAnswersNothing
	"A notification carries no id: there is nothing to answer."
	self assert: (self newProtocol handleMessage: (self requestMethod: 'notifications/initialized' id: nil)) isNil! !

!MCPServerTest methodsFor: 'as yet unclassified' stamp: 'S.V. 13/Sep/2026 12:33:13'!
test01IsBuiltWithItsCatalogue
	"The server is the composition root: it builds its catalogue from the classes
	that declare tools."
	| server |
	server := MCPServer on: 8767 tools: { MCPServerWorkspaceTools }.
	self assert: server catalogue size equals: 1.
	self assert: (server catalogue toolNamed: #print_it) notNil! !

!MCPServerTest methodsFor: 'as yet unclassified' stamp: 'S.V. 13/Sep/2026 12:33:13'!
test02AnswersARequestBodyAsJsonRpc
	"The server turns a JSON-RPC request body into a JSON-RPC response body."
	| server response |
	server := MCPServer on: 8767 tools: { MCPServerWorkspaceTools }.
	response := Json readFrom: (server handleRequestBody:
		'{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"print_it","arguments":{"code":"2 * 3"}}}') readStream.
	self assert: ((((response at: 'result') at: 'content') first) at: 'text') equals: '6'! !

!MCPServerTest methodsFor: 'as yet unclassified' stamp: 'S.V. 13/Sep/2026 12:33:13'!
test03AnswersNothingForANotification
	| server |
	server := MCPServer on: 8767 tools: { MCPServerWorkspaceTools }.
	self assert: (server handleRequestBody:
		'{"jsonrpc":"2.0","method":"notifications/initialized"}') isNil! !

!MCPServerToolCatalogueTest methodsFor: 'as yet unclassified' stamp: 'S.V. 13/Sep/2026 12:31:42'!
test01IsBuiltFromTheDeclarations
	"The catalogue is built by reading the tool declarations of the given classes."
	| catalogue |
	catalogue := MCPServerCatalogueBuilder buildFrom: { MCPServerWorkspaceTools }.
	self assert: catalogue size equals: 1.
	self assert: (catalogue toolNamed: #print_it) notNil! !

!MCPServerToolCatalogueTest methodsFor: 'as yet unclassified' stamp: 'S.V. 13/Sep/2026 12:31:42'!
test02ItsToolsRun
	"A tool taken from the catalogue can be run."
	| tool |
	tool := (MCPServerCatalogueBuilder buildFrom: { MCPServerWorkspaceTools })
		toolNamed: #print_it.
	self assert: (tool executeWith: #('2 + 2')) text equals: '4'! !

!MCPServerToolDescriptorTest methodsFor: 'as yet unclassified' stamp: 'S.V. 13/Sep/2026 12:31:29'!
test01IsBuiltFromTheMethodPragma
	"The descriptor is the declaration as data, plus a reference to the method."
	| descriptor |
	descriptor := MCPServerToolDescriptor
		forMethod: (MCPServerWorkspaceTools compiledMethodAt: #printIt:).
	self assert: descriptor name equals: #print_it.
	self assert: descriptor system equals: 'Workspace'.
	self assert: descriptor argumentNames equals: #('code').
	self assert: descriptor methodReference selector equals: #printIt:! !

!MCPServerToolDescriptorTest methodsFor: 'as yet unclassified' stamp: 'S.V. 13/Sep/2026 12:31:29'!
test02AnswersTheMethodCommentAsDescription
	"The description is the comment of the method that implements the tool."
	self assert: ((MCPServerToolDescriptor
		forMethod: (MCPServerWorkspaceTools compiledMethodAt: #printIt:)) description
			beginsWith: 'Evaluate aCodeString')! !

!MCPServerToolTest methodsFor: 'as yet unclassified' stamp: 'S.V. 13/Sep/2026 12:31:29'!
test01ExecutesTheToolAndAnswersAResult
	"Running the tool answers a result value with the printed text."
	| result |
	result := (MCPServerTool
		on: (MCPServerToolDescriptor
			forMethod: (MCPServerWorkspaceTools compiledMethodAt: #printIt:)))
				executeWith: #('1 + 1').
	self assert: result text equals: '2'.
	self assert: result isError equals: false! !

!MCPServerToolTest methodsFor: 'as yet unclassified' stamp: 'S.V. 13/Sep/2026 12:31:29'!
test02AFailingExecutionAnswersAnErrorResult
	"A failing expression answers an error result instead of raising."
	| result |
	result := (MCPServerTool
		on: (MCPServerToolDescriptor
			forMethod: (MCPServerWorkspaceTools compiledMethodAt: #printIt:)))
				executeWith: #('1 zork').
	self assert: result isError equals: true.
	self assert: (result text findString: 'MessageNotUnderstood') > 0! !

!MCPServerWorkspaceToolsTest methodsFor: 'as yet unclassified' stamp: 'S.V. 13/Sep/2026 12:31:29'!
test01PrintItEvaluatesAndAnswersThePrintedResult
	"The print-it operation: evaluate the code and answer the printed result."
	self assert: (MCPServerWorkspaceTools new printIt: '1 + 1') equals: '2'! !

!MCPServerWorkspaceToolsTest methodsFor: 'as yet unclassified' stamp: 'S.V. 13/Sep/2026 12:31:29'!
test02PrintItDeclaresTheToolWithAPragma
	"The tool declares itself: exposed name, window and argument names."
	| pragma |
	pragma := (MCPServerWorkspaceTools compiledMethodAt: #printIt:) pragmas
		detect: [ :p | (p keyword asString beginsWith: 'mcpTool') ] ifNone: [ nil ].
	self assert: pragma notNil.
	self assert: (pragma argumentAt: 1) equals: #print_it.
	self assert: (pragma argumentAt: 2) equals: 'Workspace'.
	self assert: (pragma argumentAt: 3) equals: #('code')! !
