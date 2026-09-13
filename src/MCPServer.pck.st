'Description MCP server for Cuis Smalltalk: exposes, to an agent, the tools a programmer has in the image.'!
!provides: 'MCPServer' 1 1!
!requires: 'JSON' 1 0 nil!
SystemOrganization addCategory: #MCPServer!


!classDefinition: #MCPServer category: #MCPServer!
Object subclass: #MCPServer
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'MCPServer'!
!classDefinition: 'MCPServer class' category: #MCPServer!
MCPServer class
	instanceVariableNames: ''!

!classDefinition: #MCPServerCatalogueBuilder category: #MCPServer!
Object subclass: #MCPServerCatalogueBuilder
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'MCPServer'!
!classDefinition: 'MCPServerCatalogueBuilder class' category: #MCPServer!
MCPServerCatalogueBuilder class
	instanceVariableNames: ''!

!classDefinition: #MCPServerMethodComment category: #MCPServer!
Object subclass: #MCPServerMethodComment
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'MCPServer'!
!classDefinition: 'MCPServerMethodComment class' category: #MCPServer!
MCPServerMethodComment class
	instanceVariableNames: ''!

!classDefinition: #MCPServerProtocol category: #MCPServer!
Object subclass: #MCPServerProtocol
	instanceVariableNames: 'catalogue'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'MCPServer'!
!classDefinition: 'MCPServerProtocol class' category: #MCPServer!
MCPServerProtocol class
	instanceVariableNames: ''!

!classDefinition: #MCPServerTool category: #MCPServer!
Object subclass: #MCPServerTool
	instanceVariableNames: 'descriptor'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'MCPServer'!
!classDefinition: 'MCPServerTool class' category: #MCPServer!
MCPServerTool class
	instanceVariableNames: ''!

!classDefinition: #MCPServerToolCatalogue category: #MCPServer!
Object subclass: #MCPServerToolCatalogue
	instanceVariableNames: 'tools'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'MCPServer'!
!classDefinition: 'MCPServerToolCatalogue class' category: #MCPServer!
MCPServerToolCatalogue class
	instanceVariableNames: ''!

!classDefinition: #MCPServerToolDescriptor category: #MCPServer!
Object subclass: #MCPServerToolDescriptor
	instanceVariableNames: 'name system argumentNames methodReference'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'MCPServer'!
!classDefinition: 'MCPServerToolDescriptor class' category: #MCPServer!
MCPServerToolDescriptor class
	instanceVariableNames: ''!

!classDefinition: #MCPServerToolResult category: #MCPServer!
Object subclass: #MCPServerToolResult
	instanceVariableNames: 'text isError'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'MCPServer'!
!classDefinition: 'MCPServerToolResult class' category: #MCPServer!
MCPServerToolResult class
	instanceVariableNames: ''!

!classDefinition: #MCPServerWorkspaceTools category: #MCPServer!
Object subclass: #MCPServerWorkspaceTools
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'MCPServer'!
!classDefinition: 'MCPServerWorkspaceTools class' category: #MCPServer!
MCPServerWorkspaceTools class
	instanceVariableNames: ''!


!MCPServer commentStamp: '<historical>' prior: 0!
I am the server: I own the port, the catalogue and the HTTP endpoint, and I am
the composition root of the package (the object the user creates with its
parameters and destroys when it is done). I do not speak the protocol myself: I
hand each request body to MCPServerProtocol and each response to the WebServer.!

!MCPServerCatalogueBuilder commentStamp: '<historical>' prior: 0!
I build a catalogue by reading the tool declarations. For each method of each
given class I ask for its descriptor; if it declares a tool, the tool goes into
the catalogue under the name the pragma says. The declaration and the
implementation are the same method, so they cannot drift.!

!MCPServerMethodComment commentStamp: '<historical>' prior: 0!
I read the comment of a method from its source. In Smalltalk the comment
is the first string after the message pattern, so I skip the pattern and take it.
I exist because comments live in the source file while pragmas live in the image:
the pragma gives the structure, the comment gives the prose, and both end up in
the tool description.!

!MCPServerProtocol commentStamp: '<historical>' prior: 0!
I speak MCP. I take a message (a JSON-RPC dictionary) and answer the response
dictionary, or nothing when the message is a notification. I know the protocol
methods and the shape of the answers; I know nothing about HTTP, and about the
tools I only know what the catalogue tells me.!

!MCPServerTool commentStamp: '<historical>' prior: 0!
I am a tool as a command: the descriptor says what I am, and I know how to
run the method that implements me, once, with the values I am given. I hold no
other state and I do not hold the receiver: the facade is stateless, so a fresh
instance per call is enough.!

!MCPServerToolCatalogue commentStamp: '<historical>' prior: 0!
I am the set of tools this server exposes, as a lookup by name. Once built I
do not change: that is what lets me be shared by every connection without any
lock. I am built by MCPServerCatalogueBuilder.!

!MCPServerToolDescriptor commentStamp: '<historical>' prior: 0!
I am what a tool declaration says, as data: the exposed name, the window
it comes from, its argument names, and a reference to the method that implements
it. I am a value: I hold no state of my own and change nothing. Instances are
created with the class-side factory, from a compiled method that carries the
mcpTool pragma.!

!MCPServerToolResult commentStamp: '<historical>' prior: 0!
I am what a tool answers: the text of the result and whether it is an error.
I am a value: I hold no state of my own beyond what I was created with.!

!MCPServerWorkspaceTools commentStamp: '<historical>' prior: 0!
I am the Workspace facade: the operations a programmer performs from a
Workspace pane, exposed as MCP tools. I hold no state and no window state: every
message receives what it needs as an argument.!

!MCPServer methodsFor: 'as yet unclassified' stamp: 'S.V. 13/Sep/2026 12:33:13'!
catalogue ^catalogue! !

!MCPServer methodsFor: 'as yet unclassified' stamp: 'S.V. 13/Sep/2026 12:33:13'!
destroy
	"Stop serving."
	webServer ifNotNil: [ webServer destroy ].
	webServer := nil.
	^ self! !

!MCPServer methodsFor: 'as yet unclassified' stamp: 'S.V. 13/Sep/2026 12:33:39'!
handleRequest: aWebRequest
	| body |
	body := self handleRequestBody: aWebRequest content.
	body isNil
		ifTrue: [ aWebRequest send200Response: '' ]
		ifFalse: [ aWebRequest send200Response: body contentType: 'application/json' ].
	^ self! !

!MCPServer methodsFor: 'as yet unclassified' stamp: 'S.V. 13/Sep/2026 12:33:13'!
handleRequestBody: aString
	"Answer the response body for a request body, or nil for a notification.
	Here is where JSON meets the protocol."
	| response |
	response := self protocol handleMessage: (Json readFrom: aString readStream).
	response ifNil: [ ^ nil ].
	^ Json render: response! !

!MCPServer methodsFor: 'as yet unclassified' stamp: 'S.V. 13/Sep/2026 12:33:13'!
port ^port! !

!MCPServer methodsFor: 'as yet unclassified' stamp: 'S.V. 13/Sep/2026 12:33:13'!
protocol ^ MCPServerProtocol on: catalogue! !

!MCPServer methodsFor: 'as yet unclassified' stamp: 'S.V. 13/Sep/2026 12:33:13'!
setPort: aPort catalogue: aCatalogue
	"Private. Instances are created with the class-side factory."
	port := aPort.
	catalogue := aCatalogue! !

!MCPServer methodsFor: 'as yet unclassified' stamp: 'S.V. 13/Sep/2026 12:33:13'!
start
	"Listen on the given port, loopback only, and serve the MCP endpoint."
	webServer := WebServer new listenOn: port interface: #(127 0 0 1).
	webServer addService: '/mcp' action: [ :request | self handleRequest: request ].
	^ self! !

!MCPServer class methodsFor: 'as yet unclassified' stamp: 'S.V. 13/Sep/2026 12:33:13'!
on: aPort tools: aCollectionOfClasses
	"Answer a server that exposes the tools declared by those classes on that port."
	^ self new
		setPort: aPort
		catalogue: (MCPServerCatalogueBuilder buildFrom: aCollectionOfClasses)! !

!MCPServerCatalogueBuilder class methodsFor: 'as yet unclassified' stamp: 'S.V. 13/Sep/2026 12:12:12'!
buildFrom: aCollectionOfClasses
	"Answer a catalogue with the tools declared by the pragmas of those classes."
	| tools |
	tools := Dictionary new.
	aCollectionOfClasses do: [ :aClass |
		aClass selectors do: [ :aSelector |
			| descriptor |
			descriptor := MCPServerToolDescriptor
				forMethod: (aClass compiledMethodAt: aSelector).
			descriptor ifNotNil: [
				tools at: descriptor name put: (MCPServerTool on: descriptor) ] ] ].
	^ MCPServerToolCatalogue on: tools! !

!MCPServerMethodComment class methodsFor: 'as yet unclassified' stamp: 'S.V. 13/Sep/2026 12:11:12'!
fromSource: aSourceString
	"Answer the comment of the method whose source is aSourceString, or nil if it has
	none. By convention the comment is the first quoted text after the message
	pattern: either on the pattern line or on the following lines."
	| stream |
	stream := aSourceString readStream.
	"Skip the message pattern: up to the first quote or the end of the line."
	[ stream atEnd or: [ (self isQuote: stream peek) or: [ self isLineEnd: stream peek ] ] ]
		whileFalse: [ stream next ].
	"Skip blanks."
	[ stream atEnd not and: [ self isBlank: stream peek ] ] whileTrue: [ stream next ].
	(stream atEnd or: [ (self isQuote: stream peek) not ]) ifTrue: [ ^ nil ].
	^ self readCommentFrom: stream! !

!MCPServerMethodComment class methodsFor: 'as yet unclassified' stamp: 'S.V. 13/Sep/2026 12:10:58'!
isBlank: aCharacter
	^ aCharacter = Character space or: [ aCharacter = Character lf
		or: [ aCharacter = Character cr or: [ aCharacter = Character tab ] ] ]! !

!MCPServerMethodComment class methodsFor: 'as yet unclassified' stamp: 'S.V. 13/Sep/2026 12:10:58'!
isLineEnd: aCharacter
	^ aCharacter = Character lf or: [ aCharacter = Character cr ]! !

!MCPServerMethodComment class methodsFor: 'as yet unclassified' stamp: 'S.V. 13/Sep/2026 12:10:58'!
isQuote: aCharacter ^ aCharacter = $"! !

!MCPServerMethodComment class methodsFor: 'as yet unclassified' stamp: 'S.V. 13/Sep/2026 12:11:26'!
readCommentFrom: aStream
	"Private. The stream is on the opening quote. Answer the comment text without the
	quotes, honouring doubled quotes as escaped ones."
	| out |
	out := WriteStream on: String new.
	aStream next.
	[ aStream atEnd ] whileFalse: [
		| ch |
		ch := aStream next.
		(self isQuote: ch)
			ifTrue: [
				(aStream atEnd not and: [ self isQuote: aStream peek ])
					ifTrue: [ aStream next ]
					ifFalse: [ ^ out contents ] ]
			ifFalse: [ out nextPut: ch ] ].
	^ out contents! !

!MCPServerProtocol methodsFor: 'as yet unclassified' stamp: 'S.V. 13/Sep/2026 12:32:32'!
catalogue ^catalogue! !

!MCPServerProtocol methodsFor: 'as yet unclassified' stamp: 'S.V. 13/Sep/2026 12:32:32'!
contentOf: aToolResult
	| item result |
	item := Dictionary new.
	item at: 'type' put: 'text'.
	item at: 'text' put: aToolResult text.
	result := Dictionary new.
	result at: 'content' put: (Array with: item).
	result at: 'isError' put: aToolResult isError.
	^ result! !

!MCPServerProtocol methodsFor: 'as yet unclassified' stamp: 'S.V. 13/Sep/2026 12:32:32'!
descriptionOf: aTool
	| descriptor description |
	descriptor := aTool descriptor.
	description := Dictionary new.
	description at: 'name' put: descriptor name asString.
	description at: 'description' put: descriptor description.
	description at: 'inputSchema' put: (self inputSchemaFor: descriptor).
	^ description! !

!MCPServerProtocol methodsFor: 'as yet unclassified' stamp: 'S.V. 13/Sep/2026 12:32:32'!
errorResponseFor: anId code: anInteger message: aString
	| response error |
	error := Dictionary new.
	error at: 'code' put: anInteger.
	error at: 'message' put: aString.
	response := Dictionary new.
	response at: 'jsonrpc' put: '2.0'.
	response at: 'id' put: anId.
	response at: 'error' put: error.
	^ response! !

!MCPServerProtocol methodsFor: 'as yet unclassified' stamp: 'S.V. 13/Sep/2026 12:32:32'!
handleMessage: aMessage
	"Answer the response for the message, or nil if it is a notification (no id)."
	| method id |
	method := aMessage at: 'method' ifAbsent: [ nil ].
	id := aMessage at: 'id' ifAbsent: [ nil ].
	id isNil ifTrue: [ ^ nil ].
	(method = 'initialize')
		ifTrue: [ ^ self resultResponseFor: id result: self initializeResult ].
	(method = 'tools/list')
		ifTrue: [ ^ self resultResponseFor: id result: self toolsListResult ].
	(method = 'tools/call')
		ifTrue: [ ^ self toolsCallResponseFor: id params: (aMessage at: 'params' ifAbsent: [ Dictionary new ]) ].
	(method = 'ping')
		ifTrue: [ ^ self resultResponseFor: id result: Dictionary new ].
	^ self errorResponseFor: id code: -32601 message: 'Method not found: ', method printString! !

!MCPServerProtocol methodsFor: 'as yet unclassified' stamp: 'S.V. 13/Sep/2026 12:32:32'!
initializeResult
	| result capabilities serverInfo |
	capabilities := Dictionary new.
	capabilities at: 'tools' put: Dictionary new.
	serverInfo := Dictionary new.
	serverInfo at: 'name' put: 'MCPServer'.
	serverInfo at: 'version' put: '0.1'.
	result := Dictionary new.
	result at: 'protocolVersion' put: '2025-06-18'.
	result at: 'capabilities' put: capabilities.
	result at: 'serverInfo' put: serverInfo.
	^ result! !

!MCPServerProtocol methodsFor: 'as yet unclassified' stamp: 'S.V. 13/Sep/2026 12:32:32'!
inputSchemaFor: aDescriptor
	| schema properties |
	properties := Dictionary new.
	aDescriptor argumentNames do: [ :each |
		| property |
		property := Dictionary new.
		property at: 'type' put: 'string'.
		properties at: each put: property ].
	schema := Dictionary new.
	schema at: 'type' put: 'object'.
	schema at: 'properties' put: properties.
	schema at: 'required' put: aDescriptor argumentNames asArray.
	^ schema! !

!MCPServerProtocol methodsFor: 'as yet unclassified' stamp: 'S.V. 13/Sep/2026 12:32:32'!
resultResponseFor: anId result: aDictionary
	| response |
	response := Dictionary new.
	response at: 'jsonrpc' put: '2.0'.
	response at: 'id' put: anId.
	response at: 'result' put: aDictionary.
	^ response! !

!MCPServerProtocol methodsFor: 'as yet unclassified' stamp: 'S.V. 13/Sep/2026 12:32:32'!
setCatalogue: aCatalogue
	"Private. Instances are created with the class-side factory."
	catalogue := aCatalogue! !

!MCPServerProtocol methodsFor: 'as yet unclassified' stamp: 'S.V. 13/Sep/2026 12:32:32'!
toolsCallResponseFor: anId params: aParams
	| tool |
	tool := catalogue toolNamed: (aParams at: 'name' ifAbsent: [ '' ]) asSymbol.
	tool ifNil: [
		^ self errorResponseFor: anId code: -32602
			message: 'Unknown tool: ', (aParams at: 'name' ifAbsent: [ '' ]) ].
	^ self resultResponseFor: anId
		result: (self contentOf: (tool executeWith: (self valuesFor: tool from: aParams)))! !

!MCPServerProtocol methodsFor: 'as yet unclassified' stamp: 'S.V. 13/Sep/2026 12:32:32'!
toolsListResult
	| result |
	result := Dictionary new.
	result at: 'tools' put: (catalogue tools collect: [ :each | self descriptionOf: each ]).
	^ result! !

!MCPServerProtocol methodsFor: 'as yet unclassified' stamp: 'S.V. 13/Sep/2026 12:32:32'!
valuesFor: aTool from: aParams
	"Answer the values in the order the declared arguments say."
	| arguments |
	arguments := aParams at: 'arguments' ifAbsent: [ Dictionary new ].
	^ aTool descriptor argumentNames
		collect: [ :each | arguments at: each ifAbsent: [ nil ] ]! !

!MCPServerProtocol class methodsFor: 'as yet unclassified' stamp: 'S.V. 13/Sep/2026 12:32:32'!
on: aCatalogue ^ self new setCatalogue: aCatalogue! !

!MCPServerTool methodsFor: 'as yet unclassified' stamp: 'S.V. 13/Sep/2026 12:11:45'!
descriptor ^descriptor! !

!MCPServerTool methodsFor: 'as yet unclassified' stamp: 'S.V. 13/Sep/2026 12:12:40'!
executeWith: anArrayOfValues
	"Answer the MCPServerToolResult of running this tool with the given values.
	A failing expression answers an error result instead of letting the exception
	escape: the tool is the boundary between the image and the protocol."
	^ [ | method receiver |
		method := descriptor methodReference.
		receiver := method classIsMeta
			ifTrue: [ method actualClass ]
			ifFalse: [ method actualClass new ].
		MCPServerToolResult
			text: (receiver perform: method selector withArguments: anArrayOfValues)
			isError: false ]
		on: Error
		do: [ :e | MCPServerToolResult text: e class name, ': ', e messageText isError: true ]! !

!MCPServerTool methodsFor: 'as yet unclassified' stamp: 'S.V. 13/Sep/2026 12:11:45'!
setDescriptor: aDescriptor
	"Private. Instances are created with the class-side factory."
	descriptor := aDescriptor! !

!MCPServerTool class methodsFor: 'as yet unclassified' stamp: 'S.V. 13/Sep/2026 12:11:45'!
on: aDescriptor
	^ self new setDescriptor: aDescriptor! !

!MCPServerToolCatalogue methodsFor: 'as yet unclassified' stamp: 'S.V. 13/Sep/2026 12:12:12'!
setTools: aDictionary
	"Private."
	tools := aDictionary! !

!MCPServerToolCatalogue methodsFor: 'as yet unclassified' stamp: 'S.V. 13/Sep/2026 12:12:12'!
size ^tools size! !

!MCPServerToolCatalogue methodsFor: 'as yet unclassified' stamp: 'S.V. 13/Sep/2026 12:12:12'!
toolNamed: aSymbol
	"Answer the tool with that name, or nil."
	^ tools at: aSymbol ifAbsent: [ nil ]! !

!MCPServerToolCatalogue methodsFor: 'as yet unclassified' stamp: 'S.V. 13/Sep/2026 12:32:32'!
tools
	"Answer the tools, ordered by exposed name: the catalogue is a value, so its
	enumeration must be stable."
	^ (tools values asSortedCollection: [ :a :b | a descriptor name <= b descriptor name ]) asArray! !

!MCPServerToolCatalogue class methodsFor: 'as yet unclassified' stamp: 'S.V. 13/Sep/2026 12:12:12'!
on: aDictionary
	"Private. Instances are created by the builder."
	^ self new setTools: aDictionary! !

!MCPServerToolDescriptor methodsFor: 'as yet unclassified' stamp: 'S.V. 13/Sep/2026 12:10:08'!
argumentNames ^argumentNames! !

!MCPServerToolDescriptor methodsFor: 'as yet unclassified' stamp: 'S.V. 13/Sep/2026 12:10:58'!
description
	"Answer the tool description: the comment of the method that implements it."
	^ MCPServerMethodComment fromSource: methodReference sourceCode! !

!MCPServerToolDescriptor methodsFor: 'as yet unclassified' stamp: 'S.V. 13/Sep/2026 12:10:08'!
methodReference ^methodReference! !

!MCPServerToolDescriptor methodsFor: 'as yet unclassified' stamp: 'S.V. 13/Sep/2026 12:10:08'!
name ^name! !

!MCPServerToolDescriptor methodsFor: 'as yet unclassified' stamp: 'S.V. 13/Sep/2026 12:10:08'!
setName: aSymbol system: aString argumentNames: anArray methodReference: aMethodReference
	"Private. Instances are created by the class-side factory."
	name := aSymbol.
	system := aString.
	argumentNames := anArray.
	methodReference := aMethodReference! !

!MCPServerToolDescriptor methodsFor: 'as yet unclassified' stamp: 'S.V. 13/Sep/2026 12:10:08'!
system ^system! !

!MCPServerToolDescriptor class methodsFor: 'as yet unclassified' stamp: 'S.V. 13/Sep/2026 12:10:08'!
forMethod: aCompiledMethod
	"Answer the descriptor of the tool the method declares with its mcpTool pragma,
	or nil if the method declares no tool."
	| pragma |
	pragma := self mcpToolPragmaIn: aCompiledMethod.
	pragma ifNil: [ ^ nil ].
	^ self new
		setName: (pragma argumentAt: 1)
		system: (pragma argumentAt: 2)
		argumentNames: (pragma argumentAt: 3)
		methodReference: (MethodReference method: aCompiledMethod)! !

!MCPServerToolDescriptor class methodsFor: 'as yet unclassified' stamp: 'S.V. 13/Sep/2026 12:10:08'!
mcpToolPragmaIn: aCompiledMethod
	"Answer the tool declaration pragma of the method, or nil. The keyword is
	matched by prefix so the declaration can grow without breaking this."
	^ aCompiledMethod pragmas
		detect: [ :p | (p keyword asString beginsWith: 'mcpTool') ]
		ifNone: [ nil ]! !

!MCPServerToolResult methodsFor: 'as yet unclassified' stamp: 'S.V. 13/Sep/2026 12:11:45'!
isError ^isError! !

!MCPServerToolResult methodsFor: 'as yet unclassified' stamp: 'S.V. 13/Sep/2026 12:11:45'!
setText: aString isError: aBoolean
	"Private. Instances are created with the class-side factory."
	text := aString.
	isError := aBoolean! !

!MCPServerToolResult methodsFor: 'as yet unclassified' stamp: 'S.V. 13/Sep/2026 12:11:45'!
text ^text! !

!MCPServerToolResult class methodsFor: 'as yet unclassified' stamp: 'S.V. 13/Sep/2026 12:11:45'!
text: aString isError: aBoolean
	^ self new setText: aString isError: aBoolean! !

!MCPServerWorkspaceTools methodsFor: 'as yet unclassified' stamp: 'S.V. 13/Sep/2026 12:09:50'!
printIt: aCodeString
	"Evaluate aCodeString and answer the printed representation of the result, the
	way the Workspace print-it does. The output is limited to 10000 characters,
	as in the editor."
	<mcpTool: #print_it system: 'Workspace' arguments: #('code')>
	^ (Compiler evaluate: aCodeString) printStringLimitedTo: 10000! !
