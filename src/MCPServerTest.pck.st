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

!MCPServerBrowserToolsTest methodsFor: 'testing' stamp: 'S.V. 13/Sep/2026 20:57:00'!
tearDown
	"The tests define and remove methods and classes in the scratch class: leave it clean."
	| scratch |
	#(#MCPPruebaDeClase #MCPPruebaRenombrada) do: [ :name |
		(Smalltalk at: name ifAbsent: [ nil ]) ifNotNil: [ :each | each removeFromSystem ] ].
	scratch := Smalltalk at: #MCPServerBrowserToolsScratch ifAbsent: [ nil ].
	scratch ifNil: [ ^ self ].
	#(#zap) do: [ :each |
		(scratch includesSelector: each) ifTrue: [ scratch removeSelector: each ] ]
! !

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

!MCPServerBrowserToolsTest methodsFor: 'testing' stamp: 'S.V. 13/Sep/2026 20:55:04'!
test18AnswersTheClassesOfACategory
	"The class pane: the classes of that system category, and no other."
	| text |
	text := MCPServerBrowserTools new classesInCategory: 'MCPServer'.
	self assert: (text findString: 'MCPServerBrowserTools') > 0.
	self assert: (text findString: 'MCPServerTestingTools') > 0.
	self assert: (text findString: 'Object') equals: 0! !

!MCPServerBrowserToolsTest methodsFor: 'testing' stamp: 'S.V. 13/Sep/2026 20:55:04'!
test19AnswersTheClassesMatchingAName
	"The class search: the classes whose name contains that text."
	| text |
	text := MCPServerBrowserTools new classesMatching: 'MCPServerTool'.
	self assert: (text findString: 'MCPServerToolCatalogue') > 0.
	self assert: (text findString: 'MCPServerBrowserTools') equals: 0! !

!MCPServerBrowserToolsTest methodsFor: 'testing' stamp: 'S.V. 13/Sep/2026 20:55:04'!
test20AnswersTheMethodsContainingSomeText
	"The method search: which methods contain that text in their source."
	| text |
	text := MCPServerBrowserTools new methodsContaining: 'printStringLimitedTo:'.
	self assert: (text findString: 'MCPServerWorkspaceTools>>printIt:') > 0! !

!MCPServerBrowserToolsTest methodsFor: 'testing' stamp: 'S.V. 13/Sep/2026 20:57:00'!
test21DefinesAClass
	"The class pane can create a class: name, superclass, instance variables and category."
	| class |
	MCPServerBrowserTools new
		defineClass: 'MCPPruebaDeClase'
		subclassOf: 'Object'
		variables: 'x y'
		category: 'MCPServerTest'.
	class := Smalltalk at: #MCPPruebaDeClase.
	self assert: class superclass name equals: 'Object'.
	self assert: class instVarNames asArray equals: #(#x #y).
	self assert: class category equals: #MCPServerTest
! !

!MCPServerBrowserToolsTest methodsFor: 'testing' stamp: 'S.V. 13/Sep/2026 20:57:00'!
test22RefusesToDefineAClassThatAlreadyExists
	"Defining does not redefine: a class that is already there is said, not overwritten."
	self should: [ MCPServerBrowserTools new
		defineClass: 'MCPServer'
		subclassOf: 'Object'
		variables: ''
		category: 'MCPServer' ] raise: Error
! !

!MCPServerBrowserToolsTest methodsFor: 'testing' stamp: 'S.V. 13/Sep/2026 20:57:00'!
test23RemovesAClass
	"The class pane can remove a class."
	MCPServerBrowserTools new
		defineClass: 'MCPPruebaDeClase'
		subclassOf: 'Object'
		variables: ''
		category: 'MCPServerTest'.
	MCPServerBrowserTools new removeClass: 'MCPPruebaDeClase'.
	self deny: (Smalltalk includesKey: #MCPPruebaDeClase)
! !

!MCPServerBrowserToolsTest methodsFor: 'testing' stamp: 'S.V. 13/Sep/2026 20:57:00'!
test24RenamesAClass
	"The class pane can rename a class, keeping its category."
	MCPServerBrowserTools new
		defineClass: 'MCPPruebaDeClase'
		subclassOf: 'Object'
		variables: ''
		category: 'MCPServerTest'.
	MCPServerBrowserTools new renameClass: 'MCPPruebaDeClase' to: 'MCPPruebaRenombrada'.
	self assert: (Smalltalk includesKey: #MCPPruebaRenombrada).
	self deny: (Smalltalk includesKey: #MCPPruebaDeClase).
	self assert: (Smalltalk at: #MCPPruebaRenombrada) category equals: #MCPServerTest
! !

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

!MCPServerTest methodsFor: 'testing' stamp: 'S.V. 13/Sep/2026 20:15:59'!
test06StartingRequiresAnAuthor
	"Starting does not invent an author: what the agent writes is the responsibility of
	whoever owns the image, so an image with no author is told, not started."
	| first second before |
	before := Utilities authorInitialsPerSe.
	[ Utilities setAuthorName: 'x' initials: 'S.V.'.
		first := MCPServer on: 8795 tools: { MCPServerWorkspaceTools }.
		[ first start. self assert: first port equals: 8795 ] ensure: [ first destroy ].
		Utilities setAuthorName: 'x' initials: ''.
		second := MCPServer on: 8795 tools: { MCPServerWorkspaceTools }.
		self should: [ second start ] raise: Error ]
		ensure: [ Utilities setAuthorName: 'Sebastian' initials: before ]! !

!MCPServerTest methodsFor: 'testing' stamp: 'S.V. 13/Sep/2026 20:46:29'!
test07StartingTwiceSaysItIsAlreadyListening
	"Starting a server that is already listening is said, not done: the server does not take
	a port away from anybody, not even from itself."
	| server |
	server := MCPServer on: 8796 tools: { MCPServerWorkspaceTools }.
	[ server start.
	  self should: [ server start ] raise: Error
		  withMessageText: 'Already listening on port 8796' ]
		ensure: [ server destroy ]! !

!MCPServerTest methodsFor: 'testing' stamp: 'S.V. 13/Sep/2026 21:23:15'!
test09DecodesTheBodyAsUtf8
	"The body arrives as bytes, and JSON is UTF-8 by definition: a character that takes two
	bytes on the wire has to reach the tool as one character, not two. The accent is built from
	its code point, because this source travels through the same boundary."
	| accent code body response result |
	accent := String with: (Character codePoint: 233).
	code := '| s | s := ''caf', accent, '''. s size'.
	body := '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"print_it","arguments":{"code":"',
		code, '"}}}'.
	response := (MCPServer on: 8767 tools: { MCPServerWorkspaceTools })
		handleRequestBody: body asUtf8BytesOrByteString.
	result := Json readFrom: response readStream.
	self assert: ((((result at: 'result') at: 'content') first) at: 'text') equals: '4'
! !

!MCPServerTest methodsFor: 'testing' stamp: 'S.V. 13/Sep/2026 21:23:15'!
test10EncodesTheResponseAsUtf8
	"The response leaves as UTF-8 bytes: the client can decode it and get the character back,
	instead of receiving the raw code point as a byte."
	| accent body response decoded |
	accent := String with: (Character codePoint: 233).
	body := '{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"print_it","arguments":{"code":"String with: (Character codePoint: 233)"}}}'.
	response := (MCPServer on: 8767 tools: { MCPServerWorkspaceTools }) handleRequestBody: body.
	decoded := String fromUtf8Bytes: response asByteArray.
	self assert: (decoded findString: accent) > 0
! !

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
