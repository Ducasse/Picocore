"
I'm the structure of an object (in fact any element, even classes) manipulated in a pico world. 
I'm implemented as a subclass of Array, but this is an implementation details.

As a class I define all the elementary operations that we can execute on the structure (instance of me) that represent pico objects. In a C-implementation of PicoCore all such elementary operations would be coded as function on a data structure representing an object.

My methods are often executed by the code interpreter in implicit sends (Pharo messages) and not explicit picoCore sends (e.g. using message send: #aMethodSelector).
My methods are often called from a method defined in codeRepository subclasses.


For example in the method below, the message `valueOfInstanceVariable:` is not defined in the class `PicoObjectCode` but in `PicoBlop`. This is during the interpretation of the method `introspectReadVariable:` that the method is found and executed. 
This is normal since the method `introspectReadVariable:` is interpreted with picoBlop instances as receiver and arguments.

```
PicoObjectCode >> introspectReadVariable: aSymbol

	^ self valueOfInstanceVariable: aSymbol

```

The methods in PicoObjectCode are only executed as when they are used in an explicit message send (e.g., send: ).



"
Class {
	#name : #PicoBlop,
	#superclass : #Array,
	#type : #variable,
	#classInstVars : [
		'picoEnvironment'
	],
	#category : #'PicoCore-Core'
}

{ #category : #bootstrap }
PicoBlop class >> bootstrap [

	self initializePicoClassEnvironment.
	self manuallyDefineClass.
	self defineObject.
	self defineClass
]

{ #category : #bootstrap }
PicoBlop class >> classInstanceVariables [
	^ #(#class #name #superclass #iv #methodDict)
]

{ #category : #'global class repository management' }
PicoBlop class >> declareClass: aPicoClass [ 
	"Return the class defined in the class repository with the name aSymbol"

	self picoEnvironment at: aPicoClass picoClassName put: aPicoClass 
			
]

{ #category : #bootstrap }
PicoBlop class >> defineClass [

	| picoClass |
	picoClass := PicoBlop giveClassNamed: #PicoClass.
	picoClass 
			send: #createClassNamed:inheritsFrom:instVars:
			withArguments: { #PicoClass . #PicoObject . self onlyClassInstanceVariables  }.
	
]

{ #category : #bootstrap }
PicoBlop class >> defineObject [

	| picoClass objectClass |
	"not sure that this is needed"
	PicoBlop 
		initialize;
		manuallyDefineClass.
		
	picoClass := PicoBlop giveClassNamed: #PicoClass.
	objectClass := picoClass 
			send: #createClassNamed:inheritsFrom:instVars:
			withArguments: { #PicoObject . nil . #(class)}.
	
]

{ #category : #'global class repository management' }
PicoBlop class >> giveClassNamed: aSymbol [ 
	"Return the class defined in the class repository with the name aSymbol"

	^ self 
			giveClassNamed: aSymbol 
			ifAbsent: [self error: ('The class ' , aSymbol printString , ' is not defined')]
]

{ #category : #'global class repository management' }
PicoBlop class >> giveClassNamed: aSymbol ifAbsent: aBlock [

	^ self picoEnvironment at: aSymbol ifAbsent: aBlock
]

{ #category : #'global class repository management' }
PicoBlop class >> initialize [

	self initializePicoClassEnvironment

]

{ #category : #'global class repository management' }
PicoBlop class >> initializePicoClassEnvironment [
	"could be better to have it as instance level so that we can test without breaking everything but this is a toy."
	
	picoEnvironment := Dictionary new.
	picoEnvironment at: #PicoObject put: nil.
	picoEnvironment at: #PicoClass put: nil.
]

{ #category : #'bootstrap - faked class definition' }
PicoBlop class >> manualClassStructure [
	| class |
	"we cannot use the primitive allocate because the class does not exist.
	we create really by hand the object that represent the class."
	class := self new: 5.
	class picoClassId: #PicoClass.
	class picoClassName: #PicoClass.
	class picoIVs: #(#class #name #superclass #iv #methodDict).
	"we hardcod the Class structure and the fact that class is inherited from Object."
	class picoSuperclassId: #PicoObject.
	class picoMethodDict: (IdentityDictionary new: 3).
	^ class
]

{ #category : #'bootstrap - faked class definition' }
PicoBlop class >> manuallyDefineClass [
	| picoClass |
	picoClass := self manualClassStructure.
	picoClass initializeMethodDictionaryFrom: PicoFakedClassCode.
	self declareClass: picoClass.
	^ picoClass
	
]

{ #category : #bootstrap }
PicoBlop class >> onlyClassInstanceVariables [
	^ #(#name #superclass #iv #methodDict)
]

{ #category : #'global class repository management' }
PicoBlop class >> picoEnvironment [

	^ picoEnvironment ifNil: [ self initializePicoClassEnvironment. picoEnvironment ]
]

{ #category : #allocate }
PicoBlop >> allocateAnInstance [
	"Returns a newly created instance of self, an ObjClass. In this implementation the identifier of the object class is the name of the class. "

	| a |
	a := self class new: self picoNumberOfIVs.
	a picoClassId: self picoClassName.
	^a
]

{ #category : #methods }
PicoBlop >> bodyOfMethod: aSelector [ 
	"Return the method associated with the selector <aSelector> in the receiver.
	Return nil if the selector is not defined.  self is an objClass"

	^ self picoMethodDict at: aSelector ifAbsent: [nil]
]

{ #category : #'variable inheritance' }
PicoBlop >> computeIVForBootstrapOfSuperclassSymbol: aSuperclassSymbol iv: instVars [

	aSuperclassSymbol isNil
		ifTrue: 
			[ "we are on Object since only Object does not have a superclass."
			self picoIVs: #(#class) ]
		ifFalse: 
			[ 
			| picoSuperclass | 
			picoSuperclass := PicoBlop giveClassNamed: aSuperclassSymbol.
			self picoIVs: (self computeNewIVFrom: picoSuperclass picoIVs with: instVars)].
]

{ #category : #'variable inheritance' }
PicoBlop >> computeNewIVFrom: superIVsOrderedCol with: localIVOrdCol [
	"Returns an ordered collection that is the union without duplicate of ivOfSuper and ivOrderedCollection. Important the order of the instance variable is conserved"

	| ivs |
	^ ( superIVsOrderedCol isNil 
		ifTrue: [ localIVOrdCol ]
		ifFalse: 
			[ ivs := superIVsOrderedCol asOrderedCollection copy.
			localIVOrdCol do: [:e | (ivs includes: e) ifFalse: [ ivs add: e ]].
			ivs ]) asArray
]

{ #category : #'sm data' }
PicoBlop >> create: aClassName with: aDictionary [

	| class inst |
	class := PicoBlop giveClassNamed: aClassName.
  inst := class send: #new.
	aDictionary keysAndValuesDo: [ :k :v | 
			inst setValueOfInstanceVariable: k to: v 
			].
	inst privateOwnedBySetter: self.
	^ inst
]

{ #category : #lookup }
PicoBlop >> doesUnderstand: aSelector [

	^ self picoMethodDict keys includes: aSelector
]

{ #category : #prepare }
PicoBlop >> fillUpGlobalEnvironmentOf: aPicoInterpreter [
	"fill up the global scope of the interpreter.
	We could also redefine vistiGlobalNode to get the same."
	
	self class picoEnvironment keysAndValuesDo: 
		[ :k :v | 
			aPicoInterpreter globalEnvironmentAt: k put: v] 
]

{ #category : #methods }
PicoBlop >> initializeMethodDictionaryFrom: aPharoClass [

	self picoMethodDict: (self methodDictionaryFrom: aPharoClass)

	
]

{ #category : #methods }
PicoBlop >> initializeMethodDictionaryFromCodeRepositoryFor: aSymbol [
	
	| codeClass |
	codeClass := (aSymbol, 'Code') asSymbol. 
	self initializeMethodDictionaryFrom: (self class environment 
			at: codeClass 
			ifAbsent: [ self error: codeClass, ' does not seem to exist.' ] ).

	
]

{ #category : #lookup }
PicoBlop >> lookup: selector [
	"look for the method named <selector> starting in the receiver. 
	The lookup is done for a message sent to <anObjObject>. self is an objClass"
	
	^(self doesUnderstand: selector)
		ifTrue: [ self bodyOfMethod: selector]
		ifFalse: 
			[self picoClassName = #PicoObject
				ifFalse: 
					[ (self class giveClassNamed: self picoSuperclassId) lookup: selector.]
				ifTrue: [ nil ]]
]

{ #category : #methods }
PicoBlop >> methodDictionaryFrom: aPharoClass [
	"Add AST of Pharo method of the arg to the method dictionary of the receiver.
	In addition annotate super with the definitionClass."

	| dict | 
	dict := IdentityDictionary new. 
	aPharoClass selectors do: [ :each | 
		| ast |
		ast := (RBParser parseMethod: (aPharoClass compiledMethodAt: each) sourceCode)
			propertyAt: #definingClass put: self;
			yourself.
		dict at: each put: ast.
		].
	^ dict
]

{ #category : #offsets }
PicoBlop >> offsetForClass [

	^ 1
]

{ #category : #offsets }
PicoBlop >> offsetForIVs [
	^ 4
]

{ #category : #offsets }
PicoBlop >> offsetForMethodDict [
	^ 5
]

{ #category : #offsets }
PicoBlop >> offsetForName [
	^ 2
]

{ #category : #offsets }
PicoBlop >> offsetForSuperclass [

	^3
]

{ #category : #'instance variables' }
PicoBlop >> offsetFromClassOfInstanceVariable: aSymbol [ 
	"Returns the index of the instance variable named aSymbol for an class anObjClass.
	Returns 0 if the aSymbol is not present in the instance variable lists of anObjClass"

	^ self picoIVs indexOf: aSymbol
]

{ #category : #'instance variables' }
PicoBlop >> offsetFromObjectOfInstanceVariable: aSymbol [
	"Returns the offset of the instance variable named aSymbol in the object anObjObject.
	If aSymbol is not an instance variable is not an instance variable of the object raise an error"

	| aClass |
	aClass := self picoClass.
	(aClass picoIVs includes: aSymbol) 
		ifFalse: [self error: 'The class ' , aClass objName asString
						, ' does not define the instance variable ' , aSymbol asString].
	^ aClass offsetFromClassOfInstanceVariable: aSymbol
]

{ #category : #'basic access' }
PicoBlop >> picoClass [

	^ self class giveClassNamed: self picoClassId
]

{ #category : #'object structure' }
PicoBlop >> picoClassId [

	^ self at: self offsetForClass 
]

{ #category : #'object structure' }
PicoBlop >> picoClassId: ID [

	self at: self offsetForClass put: ID
]

{ #category : #'class structure' }
PicoBlop >> picoClassName [

	^ self at: self offsetForName
]

{ #category : #'class structure' }
PicoBlop >> picoClassName: aString [

	self at: self offsetForName put: aString
]

{ #category : #'class structure' }
PicoBlop >> picoIVs [
	"Receiver should be: anObjClass. Returns the list of instance variables"
	
	^self at: self offsetForIVs
]

{ #category : #'class structure' }
PicoBlop >> picoIVs: anOrderedCollection [ 
	"Receiver should be: anObjClass. Set the list of instance variable names of the receiver (anObjClass)"

	self at: self offsetForIVs put: anOrderedCollection
]

{ #category : #'class structure' }
PicoBlop >> picoMethodDict [

	^ self at: self offsetForMethodDict
]

{ #category : #'class structure' }
PicoBlop >> picoMethodDict: aDict [

	self at: self offsetForMethodDict put: aDict
]

{ #category : #'basic access' }
PicoBlop >> picoNumberOfIVs [
	"for now class x y"
	^ self picoIVs size
]

{ #category : #'sm data' }
PicoBlop >> picoOwner [

	^ owner

	
]

{ #category : #'basic access' }
PicoBlop >> picoSuperclass [

	^ self class giveClassNamed: self picoSuperclassId
]

{ #category : #'class structure' }
PicoBlop >> picoSuperclassId [
	"Receiver should be: anObjClass. Returns the superclass id of the receiver (anObjClass)"

	^self at: self offsetForSuperclass
]

{ #category : #'class structure' }
PicoBlop >> picoSuperclassId: anObjClassId [
	"Receiver should be: anObjClass. Set the superclass id of the receiver (anObjClass)"

	self at: self offsetForSuperclass put: anObjClassId
]

{ #category : #lookup }
PicoBlop >> primitiveLookup: aSelector [

	^ self picoMethodDict at: aSelector
]

{ #category : #'sm data' }
PicoBlop >> privateOwnedBySetter: anOwner [

	owner := anOwner

	
]

{ #category : #'message passing' }
PicoBlop >> send: aSelector [

	^ self send: aSelector withArguments: #()
]

{ #category : #'message passing' }
PicoBlop >> send: aSelector withArguments: anArray [

	aSelector numArgs = anArray size 
		ifFalse: [ self error: aSelector, ' does not expect ', anArray printString  ].
	^ (self picoClass lookup: aSelector)
			ifNotNil: [ :method |  
						| interpreter |
						interpreter := PicoInterpreter2 new.
						self fillUpGlobalEnvironmentOf: interpreter. 
						interpreter
								globalEnvironmentAt: #OrderedCollection put: OrderedCollection;
								globalEnvironmentAt: #IdentityDictionary put: IdentityDictionary;
								globalEnvironmentAt: #PicoBlop put: PicoBlop;
								execute: method
								withReceiver: self 
								andArguments: anArray ]
			ifNil: [  self sendError: aSelector withArguments: anArray  ]
]

{ #category : #'message passing' }
PicoBlop >> sendError: selector withArguments: arguments [
	"send error wrapping arguments into an array with the selector as first argument. Instead of an array we should create a message object."
	
	^ self send: #error: withArguments:  {(arguments copyWithFirst: selector)}
	

]

{ #category : #'instance variables' }
PicoBlop >> setValueOfInstanceVariable: aSymbol to: value [
	"Return the value of the instance variable, aSymbol, of the receiver."
	
	self at: (self offsetFromObjectOfInstanceVariable: aSymbol) put: value 
]

{ #category : #'instance variables' }
PicoBlop >> valueOfInstanceVariable: aSymbol [ 
	"Return the value of the instance variable, aSymbol, of the receiver."

	^ self at: (self offsetFromObjectOfInstanceVariable: aSymbol)
	
]
