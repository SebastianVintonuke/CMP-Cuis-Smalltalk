'Description Tests for the MCPServer package.'!
!provides: 'MCPServerTest' 1 3!
!requires: 'MCPServer' 1 0 nil!
SystemOrganization addCategory: #MCPServerTest!


!classDefinition: #MCPServerBrowserToolsScratch category: #MCPServerTest!
Object subclass: #MCPServerBrowserToolsScratch
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'MCPServerTest'!
!classDefinition: 'MCPServerBrowserToolsScratch class' category: #MCPServerTest!
MCPServerBrowserToolsScratch class
	instanceVariableNames: ''!

!classDefinition: #MCPServerBrowserToolsTest category: #MCPServerTest!
TestCase subclass: #MCPServerBrowserToolsTest
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'MCPServerTest'!
!classDefinition: 'MCPServerBrowserToolsTest class' category: #MCPServerTest!
MCPServerBrowserToolsTest class
	instanceVariableNames: ''!

!classDefinition: #MCPServerEnvironmentTest category: #MCPServerTest!
TestCase subclass: #MCPServerEnvironmentTest
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'MCPServerTest'!
!classDefinition: 'MCPServerEnvironmentTest class' category: #MCPServerTest!
MCPServerEnvironmentTest class
	instanceVariableNames: ''!

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

!classDefinition: #MCPServerTestingToolsTest category: #MCPServerTest!
TestCase subclass: #MCPServerTestingToolsTest
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'MCPServerTest'!
!classDefinition: 'MCPServerTestingToolsTest class' category: #MCPServerTest!
MCPServerTestingToolsTest class
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


!MCPServerBrowserToolsScratch commentStamp: '<historical>' prior: 0!
I am the scratch class of the MCPServer tests: the tests define and remove methods here, so they never touch the code of the image.!

!MCPServerBrowserToolsTest commentStamp: '<historical>' prior: 0!
I test the Browser facade: the operations a programmer performs from the Browser, exposed as MCP tools.!

!MCPServerEnvironmentTest commentStamp: '<historical>' prior: 0!
I test the access to the image: the signature the changes of the agent are stamped with, and the classes by name.!

!MCPServerMethodCommentTest commentStamp: '<historical>' prior: 0!
I test the reader of a method comment, which is where the tool description comes from.!

!MCPServerProtocolTest commentStamp: '<historical>' prior: 0!
I test the MCP protocol: the message in, the response out.!

!MCPServerTestingToolsTest commentStamp: '<historical>' prior: 0!
I test the Test Runner facade: running the tests of a class, and taking the test classes of a whole package.!

!MCPServerToolCatalogueTest commentStamp: '<historical>' prior: 0!
I test the catalogue: the set of tools exposed, built from the declarations.!

!MCPServerToolDescriptorTest commentStamp: '<historical>' prior: 0!
I test the descriptor: what a tool declaration says, as data.!

!MCPServerToolTest commentStamp: '<historical>' prior: 0!
I test the tool as a command: running it and answering a result.!

!MCPServerWorkspaceToolsTest commentStamp: '<historical>' prior: 0!
I test the Workspace facade: the operations it exposes as tools.!

!MCPServerBrowserToolsTest methodsFor: 'testing' stamp: 'S.V. 13/Sep/2026 15:41:59'!
test01AnswersTheSelectorsOfBothSides
	"The class pane, the protocol pane and the selector pane: the selectors of the
	class, both sides, grouped by the method category they are classified under."
	| text |
	text := MCPServerBrowserTools new selectorsOfClass: 'MCPServerToolCatalogue'.
	self assert: (text findString: 'instance side') > 0.
	self assert: (text findString: 'class side') > 0.
	self assert: (text findString: 'setTools:') > 0.
	self assert: (text findString: 'toolNamed:') > 0! !

!MCPServerBrowserToolsTest methodsFor: 'testing' stamp: 'S.V. 13/Sep/2026 15:41:59'!
test02AnswersTheSourceOfAMethod
	"The source pane: the source of the method, comment and pragmas included."
	| text |
	text := MCPServerBrowserTools new
		sourceOfMethod: 'printIt:'
		inClass: 'MCPServerWorkspaceTools'.
	self assert: (text findString: 'mcpTool') > 0.
	self assert: (text findString: 'printStringLimitedTo:') > 0! !

!MCPServerBrowserToolsTest methodsFor: 'testing' stamp: 'S.V. 13/Sep/2026 15:41:59'!
test03ReadsTheClassSide
	"The class name says which side, the way the class pane of the Browser shows it:
	Foo class is the class side of Foo."
	| text |
	text := MCPServerBrowserTools new
		sourceOfMethod: 'on:tools:'
		inClass: 'MCPServer class'.
	self assert: (text findString: 'setPort:') > 0! !

!MCPServerBrowserToolsTest methodsFor: 'testing' stamp: 'S.V. 13/Sep/2026 15:42:44'!
test04AnswersTheClassComment
	"The class comment pane: the comment of the class, which is where the class says
	what it is for."
	| text |
	text := MCPServerBrowserTools new commentOfClass: 'MCPServerToolCatalogue'.
	self assert: (text findString: 'I am the set of tools') > 0! !

!MCPServerBrowserToolsTest methodsFor: 'testing' stamp: 'S.V. 13/Sep/2026 15:42:44'!
test05AnswersTheSendersOfASelector
	"The senders pane: which methods in the image send that selector."
	| text |
	text := MCPServerBrowserTools new allCallsOn: 'toolNamed:'.
	self assert: (text findString: 'MCPServerProtocol>>') > 0! !

!MCPServerBrowserToolsTest methodsFor: 'testing' stamp: 'S.V. 13/Sep/2026 15:42:44'!
test06SignalsAnUnknownClass
	"A tool that is given a class that does not exist says so."
	self should: [ MCPServerBrowserTools new commentOfClass: 'NoSuchClassHere' ] raise: Error! !

!MCPServerBrowserToolsTest methodsFor: 'testing' stamp: 'S.V. 13/Sep/2026 15:42:44'!
test07SignalsAnUnknownMethod
	"A tool that is given a selector the class does not understand says so."
	self should: [ MCPServerBrowserTools new
		sourceOfMethod: 'noSuchSelectorHere'
		inClass: 'MCPServer' ] raise: Error! !

!MCPServerBrowserToolsTest methodsFor: 'testing' stamp: 'S.V. 13/Sep/2026 15:43:07'!
test08CompilesAMethodInAClass
	"The source pane, after accepting: the method is in the class and it runs."
	| text scratch |
	text := MCPServerBrowserTools new
		compileMethod: 'zap ^ 6 * 7'
		inClass: 'MCPServerBrowserToolsScratch'
		classified: 'testing'.
	scratch := Smalltalk at: #MCPServerBrowserToolsScratch.
	self assert: (scratch includesSelector: #zap).
	self assert: (scratch new zap) equals: 42.
	self assert: (text findString: 'zap') > 0! !

!MCPServerBrowserToolsTest methodsFor: 'testing' stamp: 'S.V. 13/Sep/2026 15:43:17'!
test09SignalsASyntaxError
	"A source that does not compile does not get into the class."
	self should: [ MCPServerBrowserTools new
		compileMethod: 'zork ^ 1 +'
		inClass: 'MCPServerBrowserToolsScratch'
		classified: 'testing' ] raise: Error.
	self deny: ((Smalltalk at: #MCPServerBrowserToolsScratch) includesSelector: #zork)! !

!MCPServerBrowserToolsTest methodsFor: 'testing' stamp: 'S.V. 13/Sep/2026 15:43:07'!
test10RemovesAMethod
	"The Browser remove: the method goes out of the class."
	| scratch |
	MCPServerBrowserTools new
		compileMethod: 'zap ^ 6 * 7'
		inClass: 'MCPServerBrowserToolsScratch'
		classified: 'testing'.
	MCPServerBrowserTools new
		removeMethod: 'zap'
		inClass: 'MCPServerBrowserToolsScratch'.
	scratch := Smalltalk at: #MCPServerBrowserToolsScratch.
	self deny: (scratch includesSelector: #zap)! !

!MCPServerBrowserToolsTest methodsFor: 'testing' stamp: 'S.V. 13/Sep/2026 15:43:07'!
test11SignalsRemovingANonExistentMethod
	self should: [ MCPServerBrowserTools new
		removeMethod: 'noSuchMethodHere'
		inClass: 'MCPServerBrowserToolsScratch' ] raise: Error! !

!MCPServerBrowserToolsTest methodsFor: 'testing' stamp: 'S.V. 13/Sep/2026 15:44:06'!
test12DoesNotSayAsYetUnclassified
	"A side without methods says so: the empty category the image keeps around is
	not a method category."
	| text |
	text := MCPServerBrowserTools new selectorsOfClass: 'MCPServerBrowserTools'.
	self assert: (text findString: 'as yet unclassified') equals: 0.
	self assert: (text findString: 'class side: no methods') > 0! !

!MCPServerBrowserToolsTest methodsFor: 'testing' stamp: 'S.V. 13/Sep/2026 18:18:40'!
test13AnswersTheImplementorsOfASelector
	"The implementors pane: every method in the image that implements that selector,
	written the way the Browser writes a method reference."
	| text |
	text := MCPServerBrowserTools new allImplementorsOf: 'printStringLimitedTo:'.
	self assert: (text findString: '>>printStringLimitedTo:') > 0! !

!MCPServerBrowserToolsTest methodsFor: 'testing' stamp: 'S.V. 13/Sep/2026 18:18:41'!
test14AnswersTheHierarchyOfAClass
	"The class pane with the hierarchy: the chain from the root down to the class, and
	then the classes that inherit from it."
	| text |
	text := MCPServerBrowserTools new hierarchyOfClass: 'TestCase'.
	self assert: (text findString: 'TestCase') > 0.
	self assert: (text findString: 'Object') > 0.
	self assert: (text findString: 'MCPServerBrowserToolsTest') > 0! !

!MCPServerBrowserToolsTest methodsFor: 'testing' stamp: 'S.V. 13/Sep/2026 18:18:54'!
test15ClassifiesAMethodUnderACategory
	"The protocol pane: the method moves into that method category."
	| scratch |
	scratch := Smalltalk at: #MCPServerBrowserToolsScratch.
	MCPServerBrowserTools new
		compileMethod: 'zap ^ 6 * 7'
		inClass: 'MCPServerBrowserToolsScratch'
		classified: 'testing'.
	MCPServerBrowserTools new
		classifyMethod: 'zap'
		inClass: 'MCPServerBrowserToolsScratch'
		under: 'prueba'.
	self assert: (scratch organization categoryOfElement: #zap) equals: #prueba! !

!MCPServerBrowserToolsTest methodsFor: 'testing' stamp: 'S.V. 13/Sep/2026 18:59:04'!
test16WritesThePackageToAFile
	"The file out: the package goes to a file, so the code also lives outside the image."
	| path text |
	path := '/tmp/MCPServerTest-de-prueba.pck.st'.
	MCPServerBrowserTools new fileOutPackage: 'MCPServerTest' to: path.
	text := WriteStream on: String new.
	(FileEntry withAbsolutePathName: path) readStreamDo: [ :stream | text nextPutAll: stream upToEnd ].
	self assert: (text contents findString: '!!provides: ''MCPServerTest''') > 0.
	self assert: (text contents findString: 'MCPServerBrowserToolsTest') > 0.
	(FileEntry withAbsolutePathName: path) delete! !

!MCPServerBrowserToolsTest methodsFor: 'private' stamp: 'S.V. 13/Sep/2026 15:42:06'!
foo ^ MCPServerBrowserTools new! !

!MCPServerBrowserToolsTest methodsFor: 'private' stamp: 'S.V. 13/Sep/2026 15:43:07'!
tearDown
	"The tests define and remove methods in the scratch class: leave it clean."
	| scratch |
	scratch := Smalltalk at: #MCPServerBrowserToolsScratch ifAbsent: [ nil ].
	scratch ifNil: [ ^ self ].
	#(#zap) do: [ :each |
		(scratch includesSelector: each) ifTrue: [ scratch removeSelector: each ] ]! !

!MCPServerEnvironmentTest methodsFor: 'testing' stamp: 'S.V. 13/Sep/2026 20:01:56'!
test01KeepsTheHumanInitialsInside
	"The signature of the agent carries the initials of whoever the image belongs to, so the
	two are told apart in the stamp of a method."
	| before |
	before := Utilities authorInitialsPerSe.
	[ Utilities setAuthorName: 'Sebastian' initials: 'S.V.'.
	  self assert: MCPServerEnvironment authorSignature equals: 'MCP(S.V.)' ]
		ensure: [ Utilities setAuthorName: 'Sebastian' initials: before ]! !

!MCPServerEnvironmentTest methodsFor: 'testing' stamp: 'S.V. 13/Sep/2026 20:01:56'!
test02WithoutAnAuthorItIsJustTheAgent
	"An image with no author: the signature is the agent and nothing else."
	| before |
	before := Utilities authorInitialsPerSe.
	[ Utilities setAuthorName: 'x' initials: ''.
	  self assert: MCPServerEnvironment authorSignature equals: 'MCP' ]
		ensure: [ Utilities setAuthorName: 'Sebastian' initials: before ]! !

!MCPServerEnvironmentTest methodsFor: 'testing' stamp: 'S.V. 13/Sep/2026 20:01:56'!
test03DoesNotComposeOverItsOwnSignature
	"A signature that is already the agent is answered as it is: not MCP(MCP(S.V.))."
	| before |
	before := Utilities authorInitialsPerSe.
	[ Utilities setAuthorName: 'MCP server' initials: 'MCP(S.V.)'.
	  self assert: MCPServerEnvironment authorSignature equals: 'MCP(S.V.)' ]
		ensure: [ Utilities setAuthorName: 'Sebastian' initials: before ]! !

!MCPServerMethodCommentTest methodsFor: 'testing' stamp: 'S.V. 13/Sep/2026 12:31:29'!
test01AnswersTheCommentOfAMethodSource
	"The comment is the first quoted text after the message pattern; without it, nil."
	self assert: (MCPServerMethodComment fromSource: 'foo: aName
	"Does something with aName."
	^ aName') equals: 'Does something with aName.'.
	self assert: (MCPServerMethodComment fromSource: 'foo: aName
	^ aName') isNil! !

!MCPServerProtocolTest methodsFor: 'testing' stamp: 'S.V. 13/Sep/2026 12:32:11'!
test01InitializeAnswersTheProtocolVersionAndTheToolsCapability
	| response result |
	response := self newProtocol handleMessage: (self requestMethod: 'initialize' id: 1).
	result := response at: 'result'.
	self assert: (response at: 'id') equals: 1.
	self assert: (result at: 'protocolVersion') equals: '2025-06-18'.
	self assert: ((result at: 'capabilities') includesKey: 'tools').
	self assert: ((result at: 'serverInfo') at: 'name') equals: 'MCPServer'! !

!MCPServerProtocolTest methodsFor: 'testing' stamp: 'S.V. 13/Sep/2026 12:32:11'!
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

!MCPServerProtocolTest methodsFor: 'testing' stamp: 'S.V. 13/Sep/2026 12:32:11'!
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

!MCPServerProtocolTest methodsFor: 'testing' stamp: 'S.V. 13/Sep/2026 12:32:11'!
test04AnUnknownToolAnswersAProtocolError
	| response |
	response := self newProtocol handleMessage:
		(self callRequestFor: 'nope' arguments: Dictionary new).
	self assert: (response includesKey: 'error').
	self assert: ((response at: 'error') at: 'code') equals: -32602! !

!MCPServerProtocolTest methodsFor: 'testing' stamp: 'S.V. 13/Sep/2026 12:32:43'!
test05AFailingToolAnswersAnErrorResult
	| response result text |
	response := self newProtocol handleMessage:
		(self callRequestFor: 'print_it'
			arguments: (Dictionary new at: 'code' put: '1 zork'; yourself)).
	result := response at: 'result'.
	self assert: (result at: 'isError') equals: true.
	text := ((result at: 'content') first) at: 'text'.
	self assert: (text beginsWith: 'MessageNotUnderstood')! !

!MCPServerProtocolTest methodsFor: 'testing' stamp: 'S.V. 13/Sep/2026 12:32:11'!
test06ANotificationAnswersNothing
	"A notification carries no id: there is nothing to answer."
	self assert: (self newProtocol handleMessage: (self requestMethod: 'notifications/initialized' id: nil)) isNil! !

!MCPServerProtocolTest methodsFor: 'testing' stamp: 'S.V. 13/Sep/2026 18:02:07'!
test07ToolsListSaysWhichWindowEachToolComesFrom
	"Every tool says, in its metadata, which window of the image it comes from: the tool
	is the analogue of an operation the programmer does there."
	| tools tool meta |
	tools := ((self newProtocol handleMessage: (self requestMethod: 'tools/list' id: 2))
		at: 'result') at: 'tools'.
	tool := tools detect: [ :each | (each at: 'name') = 'print_it' ].
	meta := tool at: '_meta'.
	self assert: (meta at: 'system') equals: 'Workspace'! !

!MCPServerProtocolTest methodsFor: 'private' stamp: 'S.V. 13/Sep/2026 12:32:11'!
callRequestFor: aToolName arguments: aDictionary
	| request params |
	request := self requestMethod: 'tools/call' id: 3.
	params := Dictionary new.
	params at: 'name' put: aToolName.
	params at: 'arguments' put: aDictionary.
	request at: 'params' put: params.
	^ request! !

!MCPServerProtocolTest methodsFor: 'private' stamp: 'S.V. 13/Sep/2026 12:32:11'!
newProtocol
	^ MCPServerProtocol
		on: (MCPServerCatalogueBuilder buildFrom: { MCPServerWorkspaceTools })! !

!MCPServerProtocolTest methodsFor: 'private' stamp: 'S.V. 13/Sep/2026 12:32:11'!
requestMethod: aString id: anId
	| request |
	request := Dictionary new.
	request at: 'jsonrpc' put: '2.0'.
	request at: 'id' put: anId.
	request at: 'method' put: aString.
	^ request! !

!MCPServerTest methodsFor: 'testing' stamp: 'S.V. 13/Sep/2026 12:33:13'!
test01IsBuiltWithItsCatalogue
	"The server is the composition root: it builds its catalogue from the classes
	that declare tools."
	| server |
	server := MCPServer on: 8767 tools: { MCPServerWorkspaceTools }.
	self assert: server catalogue size equals: 1.
	self assert: (server catalogue toolNamed: #print_it) notNil! !

!MCPServerTest methodsFor: 'testing' stamp: 'S.V. 13/Sep/2026 12:33:13'!
test02AnswersARequestBodyAsJsonRpc
	"The server turns a JSON-RPC request body into a JSON-RPC response body."
	| server response |
	server := MCPServer on: 8767 tools: { MCPServerWorkspaceTools }.
	response := Json readFrom: (server handleRequestBody:
		'{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"print_it","arguments":{"code":"2 * 3"}}}') readStream.
	self assert: ((((response at: 'result') at: 'content') first) at: 'text') equals: '6'! !

!MCPServerTest methodsFor: 'testing' stamp: 'S.V. 13/Sep/2026 12:33:13'!
test03AnswersNothingForANotification
	| server |
	server := MCPServer on: 8767 tools: { MCPServerWorkspaceTools }.
	self assert: (server handleRequestBody:
		'{"jsonrpc":"2.0","method":"notifications/initialized"}') isNil! !

!MCPServerTest methodsFor: 'testing' stamp: 'S.V. 13/Sep/2026 15:47:55'!
test05TwoServersDoNotShareTheirState
	"Two servers are two objects: each one has its own port and its own tools."
	| one another |
	one := MCPServer on: 8798 tools: { MCPServerWorkspaceTools }.
	another := MCPServer on: 8799 tools: { MCPServerWorkspaceTools. MCPServerBrowserTools }.
	self assert: one port equals: 8798.
	self assert: another port equals: 8799.
	self assert: (one catalogue toolNamed: #print_it) notNil.
	self deny: (one catalogue toolNamed: #selectors_of_class) notNil.
	self assert: (another catalogue toolNamed: #selectors_of_class) notNil! !

!MCPServerTest methodsFor: 'testing' stamp: 'S.V. 13/Sep/2026 20:02:13'!
test06StartingSignsTheChangesOfTheAgent
	"Starting the server signs the changes of the agent, so they are told apart from the
	work of whoever owns the image."
	| server before |
	before := Utilities authorInitialsPerSe.
	server := MCPServer on: 8795 tools: { MCPServerWorkspaceTools }.
	[ server start.
	  self assert: Utilities authorInitialsPerSe equals: MCPServerEnvironment authorSignature ]
		ensure: [ server destroy. Utilities setAuthorName: 'Sebastian' initials: before ]! !

!MCPServerTestingToolsTest methodsFor: 'testing' stamp: 'S.V. 13/Sep/2026 18:58:42'!
test01RunsTheTestsOfATestClass
	"The Test Runner over one class: the counts, and the defects if there are any."
	| text |
	text := MCPServerTestingTools new runTestsInClass: 'MCPServerToolTest'.
	self assert: (text findString: '2 tests') > 0.
	self assert: (text findString: '2 passed') > 0.
	self assert: (text findString: '0 failures') > 0.
	self assert: (text findString: '0 errors') > 0! !

!MCPServerTestingToolsTest methodsFor: 'testing' stamp: 'S.V. 13/Sep/2026 18:58:42'!
test02TakesEveryTestClassOfTheCategory
	"Every test class of that category, and no other. It does not run them: running the
	very category that contains this test would call this test again."
	| suite names |
	suite := MCPServerTestingTools new suiteForCategory: 'MCPServerTest'.
	names := (suite tests collect: [ :each | each class name ]) asSet.
	self assert: names size >= 8.
	self assert: (names includes: 'MCPServerBrowserToolsTest').
	suite tests do: [ :each | self assert: (each class inheritsFrom: TestCase) ]! !

!MCPServerTestingToolsTest methodsFor: 'testing' stamp: 'S.V. 13/Sep/2026 18:58:42'!
test03SaysWhenThereIsNothingToRun
	"A class that is not a test case, or a category without tests, is said."
	self should: [ MCPServerTestingTools new runTestsInClass: 'MCPServer' ] raise: Error.
	self should: [ MCPServerTestingTools new runTestsInCategory: 'NoSuchCategory' ] raise: Error! !

!MCPServerToolCatalogueTest methodsFor: 'testing' stamp: 'S.V. 13/Sep/2026 12:31:42'!
test01IsBuiltFromTheDeclarations
	"The catalogue is built by reading the tool declarations of the given classes."
	| catalogue |
	catalogue := MCPServerCatalogueBuilder buildFrom: { MCPServerWorkspaceTools }.
	self assert: catalogue size equals: 1.
	self assert: (catalogue toolNamed: #print_it) notNil! !

!MCPServerToolCatalogueTest methodsFor: 'testing' stamp: 'S.V. 13/Sep/2026 12:31:42'!
test02ItsToolsRun
	"A tool taken from the catalogue can be run."
	| tool |
	tool := (MCPServerCatalogueBuilder buildFrom: { MCPServerWorkspaceTools })
		toolNamed: #print_it.
	self assert: (tool executeWith: #('2 + 2')) text equals: '4'! !

!MCPServerToolDescriptorTest methodsFor: 'testing' stamp: 'S.V. 13/Sep/2026 12:31:29'!
test01IsBuiltFromTheMethodPragma
	"The descriptor is the declaration as data, plus a reference to the method."
	| descriptor |
	descriptor := MCPServerToolDescriptor
		forMethod: (MCPServerWorkspaceTools compiledMethodAt: #printIt:).
	self assert: descriptor name equals: #print_it.
	self assert: descriptor system equals: 'Workspace'.
	self assert: descriptor argumentNames equals: #('code').
	self assert: descriptor methodReference selector equals: #printIt:! !

!MCPServerToolDescriptorTest methodsFor: 'testing' stamp: 'S.V. 13/Sep/2026 12:31:29'!
test02AnswersTheMethodCommentAsDescription
	"The description is the comment of the method that implements the tool."
	self assert: ((MCPServerToolDescriptor
		forMethod: (MCPServerWorkspaceTools compiledMethodAt: #printIt:)) description
			beginsWith: 'Evaluate aCodeString')! !

!MCPServerToolTest methodsFor: 'testing' stamp: 'S.V. 13/Sep/2026 12:31:29'!
test01ExecutesTheToolAndAnswersAResult
	"Running the tool answers a result value with the printed text."
	| result |
	result := (MCPServerTool
		on: (MCPServerToolDescriptor
			forMethod: (MCPServerWorkspaceTools compiledMethodAt: #printIt:)))
				executeWith: #('1 + 1').
	self assert: result text equals: '2'.
	self assert: result isError equals: false! !

!MCPServerToolTest methodsFor: 'testing' stamp: 'S.V. 13/Sep/2026 12:31:29'!
test02AFailingExecutionAnswersAnErrorResult
	"A failing expression answers an error result instead of raising."
	| result |
	result := (MCPServerTool
		on: (MCPServerToolDescriptor
			forMethod: (MCPServerWorkspaceTools compiledMethodAt: #printIt:)))
				executeWith: #('1 zork').
	self assert: result isError equals: true.
	self assert: (result text findString: 'MessageNotUnderstood') > 0! !

!MCPServerWorkspaceToolsTest methodsFor: 'testing' stamp: 'S.V. 13/Sep/2026 12:31:29'!
test01PrintItEvaluatesAndAnswersThePrintedResult
	"The print-it operation: evaluate the code and answer the printed result."
	self assert: (MCPServerWorkspaceTools new printIt: '1 + 1') equals: '2'! !

!MCPServerWorkspaceToolsTest methodsFor: 'testing' stamp: 'S.V. 13/Sep/2026 12:31:29'!
test02PrintItDeclaresTheToolWithAPragma
	"The tool declares itself: exposed name, window and argument names."
	| pragma |
	pragma := (MCPServerWorkspaceTools compiledMethodAt: #printIt:) pragmas
		detect: [ :p | (p keyword asString beginsWith: 'mcpTool') ] ifNone: [ nil ].
	self assert: pragma notNil.
	self assert: (pragma argumentAt: 1) equals: #print_it.
	self assert: (pragma argumentAt: 2) equals: 'Workspace'.
	self assert: (pragma argumentAt: 3) equals: #('code')! !
