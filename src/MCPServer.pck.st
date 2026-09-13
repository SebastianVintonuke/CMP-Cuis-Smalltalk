'Description MCP server for Cuis Smalltalk: exposes, to an agent, the tools a programmer has in the image.'!
!provides: 'MCPServer' 1 3!
!requires: 'WebClient' 1 0 nil!
!requires: 'JSON' 1 0 nil!
SystemOrganization addCategory: #MCPServer!


!classDefinition: #MCPServer category: #MCPServer!
Object subclass: #MCPServer
	instanceVariableNames: 'port catalogue webServer'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'MCPServer'!
!classDefinition: 'MCPServer class' category: #MCPServer!
MCPServer class
	instanceVariableNames: ''!

!classDefinition: #MCPServerBrowserTools category: #MCPServer!
Object subclass: #MCPServerBrowserTools
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'MCPServer'!
!classDefinition: 'MCPServerBrowserTools class' category: #MCPServer!
MCPServerBrowserTools class
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

!classDefinition: #MCPServerEnvironment category: #MCPServer!
Object subclass: #MCPServerEnvironment
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'MCPServer'!
!classDefinition: 'MCPServerEnvironment class' category: #MCPServer!
MCPServerEnvironment class
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

!classDefinition: #MCPServerTestingTools category: #MCPServer!
Object subclass: #MCPServerTestingTools
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'MCPServer'!
!classDefinition: 'MCPServerTestingTools class' category: #MCPServer!
MCPServerTestingTools class
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

!MCPServerBrowserTools commentStamp: '<historical>' prior: 0!
I am the Browser facade: the operations a programmer performs from the Browser pane, exposed as MCP tools. I read the image and I write in it: I speak the language of the class pane, the selector pane and the source pane, and I know nothing about the protocol. I hold no state and no window state.!

!MCPServerCatalogueBuilder commentStamp: '<historical>' prior: 0!
I build a catalogue by reading the tool declarations. For each method of each
given class I ask for its descriptor; if it declares a tool, the tool goes into
the catalogue under the name the pragma says. The declaration and the
implementation are the same method, so they cannot drift.!

!MCPServerEnvironment commentStamp: '<historical>' prior: 0!
I am the access to the image that every facade shares: I answer classes by the name the Browser class pane shows (the class side says Foo class), and I am where the rest of the image access will live. Nothing of mine is state: what I read is the image.!

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

!MCPServerTestingTools commentStamp: '<historical>' prior: 0!
I am the Test Runner facade: the operations a programmer performs from the Test Runner window, exposed as MCP tools. I run tests and answer what the programmer reads there: the counts and, if there are any, the defects. I hold no state.!

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

!MCPServer methodsFor: 'accessing' stamp: 'S.V. 13/Sep/2026 15:47:46'!
catalogue ^catalogue! !

!MCPServer methodsFor: 'accessing' stamp: 'S.V. 13/Sep/2026 15:47:46'!
port ^port! !

!MCPServer methodsFor: 'accessing' stamp: 'S.V. 13/Sep/2026 15:47:46'!
protocol ^ MCPServerProtocol on: catalogue! !

!MCPServer methodsFor: 'starting' stamp: 'S.V. 13/Sep/2026 20:02:28'!
start
	"Listen on the given port, loopback only, and serve the MCP endpoint."
	MCPServerEnvironment useAgentSignature.
	webServer := WebServer new listenOn: port interface: #(127 0 0 1).
	webServer addService: '/mcp' action: [ :request | self handleRequest: request ].
	^ self! !

!MCPServer methodsFor: 'stopping' stamp: 'S.V. 13/Sep/2026 15:47:46'!
destroy
	"Stop serving."
	webServer ifNotNil: [ webServer destroy ].
	webServer := nil.
	^ self! !

!MCPServer methodsFor: 'handling' stamp: 'S.V. 13/Sep/2026 12:33:39'!
handleRequest: aWebRequest
	| body |
	body := self handleRequestBody: aWebRequest content.
	body isNil
		ifTrue: [ aWebRequest send200Response: '' ]
		ifFalse: [ aWebRequest send200Response: body contentType: 'application/json' ].
	^ self! !

!MCPServer methodsFor: 'handling' stamp: 'S.V. 13/Sep/2026 12:33:13'!
handleRequestBody: aString
	"Answer the response body for a request body, or nil for a notification.
	Here is where JSON meets the protocol."
	| response |
	response := self protocol handleMessage: (Json readFrom: aString readStream).
	response ifNil: [ ^ nil ].
	^ Json render: response! !

!MCPServer methodsFor: 'private' stamp: 'S.V. 13/Sep/2026 15:47:46'!
setPort: aPort catalogue: aCatalogue
	"Private. Instances are created with the class-side factory."
	port := aPort.
	catalogue := aCatalogue! !

!MCPServer class methodsFor: 'instance creation' stamp: 'S.V. 13/Sep/2026 12:33:13'!
on: aPort tools: aCollectionOfClasses
	"Answer a server that exposes the tools declared by those classes on that port."
	^ self new
		setPort: aPort
		catalogue: (MCPServerCatalogueBuilder buildFrom: aCollectionOfClasses)! !

!MCPServerBrowserTools methodsFor: 'accessing' stamp: 'S.V. 13/Sep/2026 15:42:52'!
allCallsOn: aSelectorString
	"The senders pane: every method in the image that sends that selector, each one
	written as the Browser writes a method reference. The first 100 are listed."
	<mcpTool: #all_calls_on system: 'Browser' arguments: #('selector')>
	| references out |
	references := (Smalltalk allCallsOn: aSelectorString asSymbol)
		asSortedCollection: [ :a :b | a printString <= b printString ].
	out := WriteStream on: String new.
	out nextPutAll: references size printString, ' senders of ', aSelectorString; newLine.
	references asArray withIndexDo: [ :each :index |
		index > 100 ifTrue: [ ^ out contents ].
		out nextPutAll: (self referenceStringFor: each); newLine ].
	^ out contents! !

!MCPServerBrowserTools methodsFor: 'accessing' stamp: 'S.V. 13/Sep/2026 18:18:48'!
allImplementorsOf: aSelectorString
	"The implementors pane: every method in the image that implements that selector,
	written as the Browser writes a method reference. The first 100 are listed."
	<mcpTool: #all_implementors_of system: 'Browser' arguments: #('selector')>
	| references out |
	references := (Smalltalk allImplementorsOf: aSelectorString asSymbol)
		asSortedCollection: [ :a :b | a printString <= b printString ].
	out := WriteStream on: String new.
	out nextPutAll: references size printString, ' implementors of ', aSelectorString; newLine.
	references asArray withIndexDo: [ :each :index |
		index > 100 ifTrue: [ ^ out contents ].
		out nextPutAll: (self referenceStringFor: each); newLine ].
	^ out contents! !

!MCPServerBrowserTools methodsFor: 'accessing' stamp: 'S.V. 13/Sep/2026 18:58:42'!
commentOfClass: aClassName
	"The class comment pane: the comment of the class, which is where the class says
	what it is for. The class side answers the same comment as the class."
	<mcpTool: #comment_of_class system: 'Browser' arguments: #('class')>
	^ (MCPServerEnvironment classNamed: aClassName) comment! !

!MCPServerBrowserTools methodsFor: 'accessing' stamp: 'S.V. 13/Sep/2026 18:58:42'!
hierarchyOfClass: aClassName
	"The class pane with the hierarchy: the chain of superclasses from the root down to
	the class, and then the classes that inherit from it."
	<mcpTool: #hierarchy_of_class system: 'Browser' arguments: #('class')>
	| class chain subclasses out |
	class := MCPServerEnvironment classNamed: aClassName.
	chain := OrderedCollection new.
	chain addFirst: class.
	[ chain first superclass isNil ] whileFalse: [ chain addFirst: chain first superclass ].
	out := WriteStream on: String new.
	out nextPutAll: 'hierarchy:'; newLine.
	chain withIndexDo: [ :each :index |
		(index - 1) timesRepeat: [ out nextPut: Character space ].
		out nextPutAll: each name; newLine ].
	subclasses := (class subclasses asSortedCollection: [ :a :b | a name <= b name ]) asArray.
	out nextPutAll: 'subclasses (', subclasses size printString, '):'.
	subclasses isEmpty
		ifTrue: [ out nextPutAll: ' none' ]
		ifFalse: [ subclasses do: [ :each | out nextPutAll: ' ', each name ] ].
	out newLine.
	^ out contents! !

!MCPServerBrowserTools methodsFor: 'accessing' stamp: 'S.V. 13/Sep/2026 18:58:42'!
selectorsOfClass: aClassName
	"The class pane, the protocol pane and the selector pane: the selectors of the
	class named aClassName, grouped by the method category they are classified under.
	A name ending in ' class' means the class side, the way the class pane shows it."
	<mcpTool: #selectors_of_class system: 'Browser' arguments: #('class')>
	| class out |
	class := MCPServerEnvironment classNamed: aClassName.
	out := WriteStream on: String new.
	self writeSelectorsOf: class on: out.
	class isMeta ifFalse: [ self writeSelectorsOf: class class on: out ].
	^ out contents! !

!MCPServerBrowserTools methodsFor: 'accessing' stamp: 'S.V. 13/Sep/2026 18:58:42'!
sourceOfMethod: aSelectorString inClass: aClassName
	"The source pane: the source of that method of that class, comment and pragmas
	included."
	<mcpTool: #source_of_method_in_class system: 'Browser' arguments: #('selector' 'class')>
	| class selector |
	class := MCPServerEnvironment classNamed: aClassName.
	selector := aSelectorString asSymbol.
	(class includesSelector: selector) ifFalse: [
		Error signal: 'No method ', aSelectorString, ' in ', class name ].
	^ (class compiledMethodAt: selector) sourceCode! !

!MCPServerBrowserTools methodsFor: 'private' stamp: 'S.V. 13/Sep/2026 15:42:52'!
referenceStringFor: aMethodReference
	"Private. The method reference as the Browser writes it: the class, the word class
	when it is the class side, and the selector."
	^ aMethodReference actualClass name, '>>', aMethodReference selector asString! !

!MCPServerBrowserTools methodsFor: 'private' stamp: 'S.V. 13/Sep/2026 15:44:13'!
writeSelectorsOf: aClass on: aStream
	"Private. One line per method category with its selectors: what the protocol pane
	and the selector pane show. A side without methods says so, instead of showing the
	empty category the image keeps around."
	| side wrote |
	side := aClass isMeta ifTrue: [ 'class side' ] ifFalse: [ 'instance side' ].
	wrote := false.
	aClass organization categories asSortedCollection do: [ :category |
		| selectors |
		selectors := (aClass organization listAtCategoryNamed: category) asSortedCollection.
		selectors isEmpty ifFalse: [
			wrote ifFalse: [
				aStream nextPutAll: side; nextPut: $:; newLine.
				wrote := true ].
			aStream nextPutAll: '  ', category asString, ': '.
			selectors do: [ :each | aStream nextPutAll: each asString; nextPut: Character space ].
			aStream newLine ] ].
	wrote ifFalse: [ aStream nextPutAll: side, ': no methods'; newLine ]! !

!MCPServerBrowserTools methodsFor: 'editing' stamp: 'S.V. 13/Sep/2026 18:58:42'!
classifyMethod: aSelectorString inClass: aClassName under: aCategoryString
	"The protocol pane: move that method of that class into that method category."
	<mcpTool: #classify_method_in_class_under system: 'Browser' arguments: #('selector' 'class' 'category')>
	| class selector |
	class := MCPServerEnvironment classNamed: aClassName.
	selector := aSelectorString asSymbol.
	(class includesSelector: selector) ifFalse: [
		Error signal: 'No method ', aSelectorString, ' in ', class name ].
	class organization classify: selector under: aCategoryString asSymbol.
	^ 'Classified ', aSelectorString, ' in ', class name, ' under ', aCategoryString! !

!MCPServerBrowserTools methodsFor: 'editing' stamp: 'S.V. 13/Sep/2026 18:58:42'!
compileMethod: aSourceString inClass: aClassName classified: aCategoryString
	"The source pane, after accepting: compile that source in that class, under that
	method category. A source that does not compile answers the syntax error and
	changes nothing."
	<mcpTool: #compile_method_in_class_classified system: 'Browser' arguments: #('source' 'class' 'category')>
	| class selector out |
	class := MCPServerEnvironment classNamed: aClassName.
	selector := class compile: aSourceString classified: aCategoryString asSymbol.
	out := WriteStream on: String new.
	out nextPutAll: 'Compiled ', class name, '>>', selector asString, ' in category ', aCategoryString, ':'.
	out newLine.
	out nextPutAll: (class compiledMethodAt: selector) sourceCode.
	^ out contents! !

!MCPServerBrowserTools methodsFor: 'editing' stamp: 'S.V. 13/Sep/2026 18:58:42'!
removeMethod: aSelectorString inClass: aClassName
	"The Browser remove: take that method out of that class. A selector the class does
	not understand is said, not removed."
	<mcpTool: #remove_method_in_class system: 'Browser' arguments: #('selector' 'class')>
	| class selector |
	class := MCPServerEnvironment classNamed: aClassName.
	selector := aSelectorString asSymbol.
	(class includesSelector: selector) ifFalse: [
		Error signal: 'No method ', aSelectorString, ' in ', class name ].
	class removeSelector: selector.
	^ 'Removed ', aSelectorString, ' from ', class name! !

!MCPServerBrowserTools methodsFor: 'file out' stamp: 'S.V. 13/Sep/2026 18:59:32'!
fileOutPackage: aCategoryName to: aFilePath
	"The file out of the Browser: write the package of that category to that file, so the
	code lives outside the image too. The usual destination is the image's Packages
	directory, but any path is allowed, and the file is overwritten."
	<mcpTool: #file_out_package_to system: 'Browser' arguments: #('category' 'path')>
	| package file |
	package := CodePackage packageOfSystemCategory: aCategoryName asSymbol ifNone: [ nil ].
	package ifNil: [ Error signal: 'No package for the category ', aCategoryName ].
	file := FileEntry withAbsolutePathName: aFilePath.
	file exists ifTrue: [ file delete ].
	file writeStreamDo: [ :stream | package writeOnStream: stream ].
	^ 'Wrote ', aCategoryName, ' to ', aFilePath! !

!MCPServerCatalogueBuilder class methodsFor: 'building' stamp: 'S.V. 13/Sep/2026 12:12:12'!
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

!MCPServerEnvironment class methodsFor: 'accessing' stamp: 'S.V. 13/Sep/2026 20:02:13'!
agentInitials
	"Answer the initials the changes of the agent are stamped with."
	^ 'MCP'! !

!MCPServerEnvironment class methodsFor: 'accessing' stamp: 'S.V. 13/Sep/2026 20:02:13'!
agentName
	"Answer the name the changes of the agent are stamped with."
	^ 'MCP server'! !

!MCPServerEnvironment class methodsFor: 'accessing' stamp: 'S.V. 13/Sep/2026 20:02:13'!
authorSignature
	"Answer the signature the changes of the agent are stamped with: the agent, and inside
	the initials of whoever the image belongs to, so the two are told apart. Reading the
	author does not ask the human anything, and a signature that is already the agent's is
	answered as it is, so it never composes over itself."
	| human |
	human := Utilities authorInitialsPerSe.
	(human isNil or: [ human isEmpty ]) ifTrue: [ ^ self agentInitials ].
	(human beginsWith: self agentInitials) ifTrue: [ ^ human ].
	^ self agentInitials, '(', human, ')'! !

!MCPServerEnvironment class methodsFor: 'accessing' stamp: 'S.V. 13/Sep/2026 18:58:42'!
classNamed: aString
	"Answer the class named aString, or its metaclass when the name ends in ' class',
	the way the class pane of the Browser shows the class side. A name that is not a
	class is said, not answered with nil."
	| theName theClass |
	theName := aString asString.
	(theName endsWith: ' class') ifTrue: [
		^ (self classNamed: (theName copyFrom: 1 to: theName size - 6)) class ].
	theClass := Smalltalk at: theName asSymbol ifAbsent: [ nil ].
	theClass ifNil: [ Error signal: 'No class named ', theName printString ].
	^ theClass! !

!MCPServerEnvironment class methodsFor: 'accessing' stamp: 'S.V. 13/Sep/2026 20:02:13'!
useAgentSignature
	"Sign the changes of the agent from here on: what the agent writes is stamped as the
	agent's, keeping the initials of the image's owner inside."
	Utilities setAuthorName: self agentName initials: self authorSignature.
	^ self authorSignature! !

!MCPServerMethodComment class methodsFor: 'reading' stamp: 'S.V. 13/Sep/2026 12:11:12'!
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

!MCPServerMethodComment class methodsFor: 'reading' stamp: 'S.V. 13/Sep/2026 12:11:26'!
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

!MCPServerMethodComment class methodsFor: 'private' stamp: 'S.V. 13/Sep/2026 12:10:58'!
isBlank: aCharacter
	^ aCharacter = Character space or: [ aCharacter = Character lf
		or: [ aCharacter = Character cr or: [ aCharacter = Character tab ] ] ]! !

!MCPServerMethodComment class methodsFor: 'private' stamp: 'S.V. 13/Sep/2026 12:10:58'!
isLineEnd: aCharacter
	^ aCharacter = Character lf or: [ aCharacter = Character cr ]! !

!MCPServerMethodComment class methodsFor: 'private' stamp: 'S.V. 13/Sep/2026 12:10:58'!
isQuote: aCharacter ^ aCharacter = $"! !

!MCPServerProtocol methodsFor: 'accessing' stamp: 'S.V. 13/Sep/2026 12:32:32'!
catalogue ^catalogue! !

!MCPServerProtocol methodsFor: 'handling' stamp: 'S.V. 13/Sep/2026 12:32:32'!
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

!MCPServerProtocol methodsFor: 'handling' stamp: 'S.V. 13/Sep/2026 12:32:32'!
toolsCallResponseFor: anId params: aParams
	| tool |
	tool := catalogue toolNamed: (aParams at: 'name' ifAbsent: [ '' ]) asSymbol.
	tool ifNil: [
		^ self errorResponseFor: anId code: -32602
			message: 'Unknown tool: ', (aParams at: 'name' ifAbsent: [ '' ]) ].
	^ self resultResponseFor: anId
		result: (self contentOf: (tool executeWith: (self valuesFor: tool from: aParams)))! !

!MCPServerProtocol methodsFor: 'handling' stamp: 'S.V. 13/Sep/2026 12:32:32'!
valuesFor: aTool from: aParams
	"Answer the values in the order the declared arguments say."
	| arguments |
	arguments := aParams at: 'arguments' ifAbsent: [ Dictionary new ].
	^ aTool descriptor argumentNames
		collect: [ :each | arguments at: each ifAbsent: [ nil ] ]! !

!MCPServerProtocol methodsFor: 'answers' stamp: 'S.V. 13/Sep/2026 12:32:32'!
contentOf: aToolResult
	| item result |
	item := Dictionary new.
	item at: 'type' put: 'text'.
	item at: 'text' put: aToolResult text.
	result := Dictionary new.
	result at: 'content' put: (Array with: item).
	result at: 'isError' put: aToolResult isError.
	^ result! !

!MCPServerProtocol methodsFor: 'answers' stamp: 'S.V. 13/Sep/2026 18:02:15'!
descriptionOf: aTool
	"Answer the tool as the protocol describes it: the name it is called by, the comment
	of the method as its description, the arguments the pragma declares, and where it
	comes from (the window of the image it is the analogue of)."
	| descriptor description meta |
	descriptor := aTool descriptor.
	description := Dictionary new.
	description at: 'name' put: descriptor name asString.
	description at: 'description' put: descriptor description.
	description at: 'inputSchema' put: (self inputSchemaFor: descriptor).
	meta := Dictionary new.
	meta at: 'system' put: descriptor system.
	description at: '_meta' put: meta.
	^ description! !

!MCPServerProtocol methodsFor: 'answers' stamp: 'S.V. 13/Sep/2026 12:32:32'!
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

!MCPServerProtocol methodsFor: 'answers' stamp: 'S.V. 13/Sep/2026 12:32:32'!
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

!MCPServerProtocol methodsFor: 'answers' stamp: 'S.V. 13/Sep/2026 12:32:32'!
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

!MCPServerProtocol methodsFor: 'answers' stamp: 'S.V. 13/Sep/2026 12:32:32'!
resultResponseFor: anId result: aDictionary
	| response |
	response := Dictionary new.
	response at: 'jsonrpc' put: '2.0'.
	response at: 'id' put: anId.
	response at: 'result' put: aDictionary.
	^ response! !

!MCPServerProtocol methodsFor: 'answers' stamp: 'S.V. 13/Sep/2026 12:32:32'!
toolsListResult
	| result |
	result := Dictionary new.
	result at: 'tools' put: (catalogue tools collect: [ :each | self descriptionOf: each ]).
	^ result! !

!MCPServerProtocol methodsFor: 'private' stamp: 'S.V. 13/Sep/2026 12:32:32'!
setCatalogue: aCatalogue
	"Private. Instances are created with the class-side factory."
	catalogue := aCatalogue! !

!MCPServerProtocol class methodsFor: 'instance creation' stamp: 'S.V. 13/Sep/2026 12:32:32'!
on: aCatalogue ^ self new setCatalogue: aCatalogue! !

!MCPServerTestingTools methodsFor: 'running' stamp: 'S.V. 13/Sep/2026 18:58:42'!
runTestsInCategory: aCategoryName
	"The Test Runner over a whole package: every test class of that category, in one run."
	<mcpTool: #run_tests_in_category system: 'Test Runner' arguments: #('category')>
	^ self summaryOfRunning: (self suiteForCategory: aCategoryName)! !

!MCPServerTestingTools methodsFor: 'running' stamp: 'S.V. 13/Sep/2026 18:58:42'!
runTestsInClass: aClassName
	"The Test Runner over one test class: run its tests and answer the summary."
	<mcpTool: #run_tests_in_class system: 'Test Runner' arguments: #('class')>
	| class suite |
	class := self testClassNamed: aClassName.
	suite := TestSuite new.
	class addToSuiteFromSelectors: suite.
	^ self summaryOfRunning: suite! !

!MCPServerTestingTools methodsFor: 'private' stamp: 'S.V. 13/Sep/2026 18:58:42'!
suiteForCategory: aCategoryName
	"Private. Answer a suite with the tests of every test class of that category."
	| category classes suite |
	category := aCategoryName asSymbol.
	classes := (TestCase subclasses select: [ :each | each category = category ])
		asSortedCollection: [ :a :b | a name <= b name ].
	classes isEmpty ifTrue: [ Error signal: 'No test classes in category ', aCategoryName ].
	suite := TestSuite new.
	classes do: [ :each | each addToSuiteFromSelectors: suite ].
	^ suite! !

!MCPServerTestingTools methodsFor: 'private' stamp: 'S.V. 13/Sep/2026 18:58:42'!
summaryOfRunning: aSuite
	"Private. Run the suite and answer it as the Test Runner shows it: the counts and,
	when there are any, each defect with its description."
	| result out |
	result := aSuite run.
	out := WriteStream on: String new.
	out nextPutAll: result runCount printString, ' tests, ',
		result passedCount printString, ' passed, ',
		result failureCount printString, ' failures, ',
		result errorCount printString, ' errors'.
	out newLine.
	result failures do: [ :each | out nextPutAll: 'FAILURE ', each printString; newLine ].
	result errors do: [ :each | out nextPutAll: 'ERROR ', each printString; newLine ].
	^ out contents! !

!MCPServerTestingTools methodsFor: 'private' stamp: 'S.V. 13/Sep/2026 18:58:42'!
testClassNamed: aString
	"Private. Answer the class named aString, which has to be a test case."
	| class |
	class := MCPServerEnvironment classNamed: aString.
	((class inheritsFrom: TestCase) or: [ class == TestCase ])
		ifFalse: [ Error signal: aString, ' is not a test case' ].
	^ class! !

!MCPServerTool methodsFor: 'accessing' stamp: 'S.V. 13/Sep/2026 12:11:45'!
descriptor ^descriptor! !

!MCPServerTool methodsFor: 'running' stamp: 'S.V. 13/Sep/2026 12:12:40'!
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

!MCPServerTool methodsFor: 'private' stamp: 'S.V. 13/Sep/2026 12:11:45'!
setDescriptor: aDescriptor
	"Private. Instances are created with the class-side factory."
	descriptor := aDescriptor! !

!MCPServerTool class methodsFor: 'instance creation' stamp: 'S.V. 13/Sep/2026 12:11:45'!
on: aDescriptor
	^ self new setDescriptor: aDescriptor! !

!MCPServerToolCatalogue methodsFor: 'accessing' stamp: 'S.V. 13/Sep/2026 12:12:12'!
size ^tools size! !

!MCPServerToolCatalogue methodsFor: 'accessing' stamp: 'S.V. 13/Sep/2026 12:12:12'!
toolNamed: aSymbol
	"Answer the tool with that name, or nil."
	^ tools at: aSymbol ifAbsent: [ nil ]! !

!MCPServerToolCatalogue methodsFor: 'accessing' stamp: 'S.V. 13/Sep/2026 12:32:32'!
tools
	"Answer the tools, ordered by exposed name: the catalogue is a value, so its
	enumeration must be stable."
	^ (tools values asSortedCollection: [ :a :b | a descriptor name <= b descriptor name ]) asArray! !

!MCPServerToolCatalogue methodsFor: 'private' stamp: 'S.V. 13/Sep/2026 12:12:12'!
setTools: aDictionary
	"Private."
	tools := aDictionary! !

!MCPServerToolCatalogue class methodsFor: 'instance creation' stamp: 'S.V. 13/Sep/2026 12:12:12'!
on: aDictionary
	"Private. Instances are created by the builder."
	^ self new setTools: aDictionary! !

!MCPServerToolDescriptor methodsFor: 'accessing' stamp: 'S.V. 13/Sep/2026 12:10:08'!
argumentNames ^argumentNames! !

!MCPServerToolDescriptor methodsFor: 'accessing' stamp: 'S.V. 13/Sep/2026 12:10:08'!
methodReference ^methodReference! !

!MCPServerToolDescriptor methodsFor: 'accessing' stamp: 'S.V. 13/Sep/2026 12:10:08'!
name ^name! !

!MCPServerToolDescriptor methodsFor: 'accessing' stamp: 'S.V. 13/Sep/2026 12:10:08'!
system ^system! !

!MCPServerToolDescriptor methodsFor: 'describing' stamp: 'S.V. 13/Sep/2026 12:10:58'!
description
	"Answer the tool description: the comment of the method that implements it."
	^ MCPServerMethodComment fromSource: methodReference sourceCode! !

!MCPServerToolDescriptor methodsFor: 'private' stamp: 'S.V. 13/Sep/2026 12:10:08'!
setName: aSymbol system: aString argumentNames: anArray methodReference: aMethodReference
	"Private. Instances are created by the class-side factory."
	name := aSymbol.
	system := aString.
	argumentNames := anArray.
	methodReference := aMethodReference! !

!MCPServerToolDescriptor class methodsFor: 'instance creation' stamp: 'S.V. 13/Sep/2026 12:10:08'!
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

!MCPServerToolDescriptor class methodsFor: 'private' stamp: 'S.V. 13/Sep/2026 12:10:08'!
mcpToolPragmaIn: aCompiledMethod
	"Answer the tool declaration pragma of the method, or nil. The keyword is
	matched by prefix so the declaration can grow without breaking this."
	^ aCompiledMethod pragmas
		detect: [ :p | (p keyword asString beginsWith: 'mcpTool') ]
		ifNone: [ nil ]! !

!MCPServerToolResult methodsFor: 'accessing' stamp: 'S.V. 13/Sep/2026 12:11:45'!
isError ^isError! !

!MCPServerToolResult methodsFor: 'accessing' stamp: 'S.V. 13/Sep/2026 12:11:45'!
text ^text! !

!MCPServerToolResult methodsFor: 'private' stamp: 'S.V. 13/Sep/2026 12:11:45'!
setText: aString isError: aBoolean
	"Private. Instances are created with the class-side factory."
	text := aString.
	isError := aBoolean! !

!MCPServerToolResult class methodsFor: 'instance creation' stamp: 'S.V. 13/Sep/2026 12:11:45'!
text: aString isError: aBoolean
	^ self new setText: aString isError: aBoolean! !

!MCPServerWorkspaceTools methodsFor: 'evaluating' stamp: 'S.V. 13/Sep/2026 12:09:50'!
printIt: aCodeString
	"Evaluate aCodeString and answer the printed representation of the result, the
	way the Workspace print-it does. The output is limited to 10000 characters,
	as in the editor."
	<mcpTool: #print_it system: 'Workspace' arguments: #('code')>
	^ (Compiler evaluate: aCodeString) printStringLimitedTo: 10000! !
