"
I'm a special Pharo interpreter. 
I bind self to `PicoBlop` instances and my lookup in not using Pharo classes but 
PicoBlop instances representing classes. 

## Link between picoBlop instances representing classes and code repo classes

Each `PicoBlop` instances representing a class is linked to a Pharo class (ending by Code) that acts as a code repository. 
For example the class `PicoPointCode` is holding methods of the method dictionary of the picoBlop class `PicoPoint`. `PicoPoint` class is NOT a Pharo class it is a picoCore instance (of picoCore metaclass). 

## About method lookup. 
As a special interpreter I interpret explicit message sends, i.e., 
message whose selector are `#send:` or `#send:withArguments:` by doing a lookup of the method in the corresponding code repository class (`PicoPointCode`).
So the lookup looks for the methods inside CodeRepository classes using the inheritance structure held in PicoBlop instances. It means that the navigation to superclasses use the picoblop instance but use 
the Pharo classes to get the actual AST of the method.


"
Class {
	#name : #PicoInterpreter2,
	#superclass : #CHInterpreter,
	#category : #'PicoCore-Core'
}

{ #category : #visiting }
PicoInterpreter2 >> classOf: aPicoObject [

	^ aPicoObject picoClass
]

{ #category : #visiting }
PicoInterpreter2 >> instanceScopeClass [
	^ PicoInstanceScope
]

{ #category : #visiting }
PicoInterpreter2 >> lookup: aSelector fromClass: aPicoClass [

	"Returns and AST
	We are visiting a Message node in the form:
	
	bla send: #foo
	
	Assumption: aSelector is #foo and not #send
	"
	^ aPicoClass lookup: aSelector
]

{ #category : #visiting }
PicoInterpreter2 >> send: aSelector receiver: newReceiver lookupFromClass: lookupClass arguments: argumentArray [

	"Handle pico sends. Pico sends are always in the form
	
	receiver send: #selector.
	
	or
	
	receiver send: #selector withArguments: arrayOfArguments.
	
	Thus, the actual selector (send: or send:withArguments:) is to be ignored.
	Take the real selector and arguments from the arguments array instead.
	"	
	^ super
		send: argumentArray first
		receiver: newReceiver
		lookupFromClass: lookupClass
		arguments: (argumentArray size > 1 ifTrue: [argumentArray second ] ifFalse: [ #() ])
]

{ #category : #visiting }
PicoInterpreter2 >> superclassOf: aPicoObject [

	^ aPicoObject picoSuperclass
]

{ #category : #visiting }
PicoInterpreter2 >> visitMessageNode: aMessageNode [
	| sel |
	sel := aMessageNode selector.
	((sel = #send:) or: [ self = #send:withArguments: ])
		ifTrue: [ ^ super visitMessageNode: aMessageNode ].

	"Here is the primitive case. The message send is to a Pharo object and not a Pico object.
	Receiver is not a pico thing, and could/should be resolved using some other mechanism (Smalltalk at:?).
	This would help to not mix Pico and not Pico things.
	Arguments should still be visited as they could be pico expressions."
	^ (self visitNode: aMessageNode receiver)
		perform: aMessageNode selector
		withArguments: (aMessageNode arguments collect: [:each | self visitNode: each ] ) asArray

]
