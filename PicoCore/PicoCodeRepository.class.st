"
This class is to keep the methods of the pico core classes.

Pay attention the methods in this class and subclasses are only executed as when they are used in an explicit message send (e.g., send: ).

The implicit sends (Pharo sends without send: ) are considered as primitive functions
and they are not explicitly lookup in the code repository classes. 
In general they are defined in the class `PicoBlop`. 
"
Class {
	#name : #PicoCodeRepository,
	#superclass : #Object,
	#type : #variable,
	#instVars : [
		'color',
		'x',
		'y'
	],
	#category : #'PicoCore-CoreCodeRepository'
}

{ #category : #'environment access' }
PicoCodeRepository >> picoClassNamed: aName [ 
	
	^ PicoBlop giveClassNamed: aName
]
